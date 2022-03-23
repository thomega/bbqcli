(* bbqcli.ml -- CLI etc. for the WLANThermo API *)

let host_default = "wlanthermo"
let program_name = "bbqcli"

module WT = WLANThermo

let print_json j =
  Yojson.Basic.pretty_to_string j |> print_endline

open Cmdliner

module type Common =
  sig
    val man_footer : Manpage.block list
    val term : ThoCurl.options Term.t
  end

module Common : Common =
  struct 

    let man_footer =
      [ `S Manpage.s_files;
        `P "None, so far.";
        `S Manpage.s_authors;
        `P "Thorsten Ohl <ohl@physik.uni-wuerzburg.de>.";
        `S Manpage.s_bugs;
        `P "Report bugs to <ohl@physik.uni-wuerzburg.de>." ]

    let docs = Manpage.s_common_options

    let ssl_arg =
      let doc = "Use SSL to connect to the host. \
                 This option should never be necessary or even used, \
                 because WLANThermo does not understand SSL." in
      let env = Cmd.Env.info "WLANTHERMO_SSL" in
      let open Arg in
      value
      & opt bool ~vopt:true false
      & info ["s"; "ssl"] ~docv:"true/false" ~doc ~docs ~env

    let host_arg =
      let doc = "Connect to the host $(docv)." in
      let env = Cmd.Env.info "WLANTHERMO_HOST" in
      let open Arg in
      value
      & opt string host_default
      & info ["H"; "host"] ~docv:"HOST" ~doc ~docs ~env

    let verbose_arg =
      let doc = "Be more verbose." in
      let env = Cmd.Env.info "WLANTHERMO_VERBOSITY" in
      let open Arg in
      value
      & opt int 0
      & info ["v"; "verbosity"; "verbose"] ~docv:"VERBOSITY" ~doc ~docs ~env

    let timeout_arg =
      let doc = "Wait only $(docv) for response." in
      let env = Cmd.Env.info "WLANTHERMO_TIMEOUT" in
      let open Arg in
      value
      & opt (some int) None
      & info ["T"; "timeout"] ~docv:"SECONDS" ~doc ~docs ~env

    let term =
      let open Term in
      const
        (fun ssl host verbosity timeout ->
          { ThoCurl.ssl; ThoCurl.host; ThoCurl.verbosity; ThoCurl.timeout })
      $ ssl_arg
      $ host_arg
      $ verbose_arg
      $ timeout_arg

  end

let all_arg =
  let doc = "Include the inactive channels." in
  let open Arg in
  value
  & flag
  & info ["a"; "all"] ~doc

module Channels : sig val term : int list Term.t end =
  struct

    (* int list list *)
    let channels_arg =
      let doc = "Select the channel(s) $(docv) (can be repeated)." in
      let open Arg in
      value
      & opt_all (list int) []
      & info ["c"; "channel"] ~docv:"N[,M...]" ~doc

    (* (int * int) list list *)
    let channel_ranges_arg =
      let doc = "Select the channels in the range $(docv) (can be repeated)." in
      let open Arg in
      value
      & opt_all (list (pair ~sep:'-' int int)) []
      & info ["C"; "channels"] ~docv:"FROM-TO" ~doc

    let term =
      let open Term in
      const
        (fun channels channel_ranges ->
          ThoList.merge_integer_ranges channels channel_ranges)
      $ channels_arg
      $ channel_ranges_arg

  end


module type Unit_Cmd =
  sig
    val cmd : unit Cmd.t
  end

module Temperature : Unit_Cmd =
  struct

    let print_temperatures ?all common channels =
      WT.format_channels ?all common channels |> List.iter print_endline

    let term =
      let open Term in
      const
        (fun common all channels ->
          print_temperatures ~all common channels)
      $ Common.term
      $ all_arg
      $ Channels.term

    let cmd =
      Cmd.v (Cmd.info "temperature") term

end

module Alarm : Unit_Cmd =
  struct

    (* Put the long form of equivalent options last so that they are
       used for the description of the default in the manpage. *)
    let switch_list = [("+", WT.On); ("on", WT.On); ("-", WT.Off); ("off", WT.Off)]
    let switch = Arg.enum switch_list
    let switch_docv = String.concat "|" (List.map fst switch_list)

    (* (float * float) option *)
    let range_arg =
      let doc = "Select the temperature range $(docv)." in
      let open Arg in
      value
      & opt (some (pair ~sep:'-' float float)) None
      & info ["t"; "temperature"; "temp"] ~docv:"MIN-MAX" ~doc

    (* float option *)
    let min_arg =
      let doc = "Select the lower temperature limit $(docv).  \
                 This takes precedence over the lower limit of a \
                 range specified in --temperature." in
      let open Arg in
      value
      & opt (some float) None
      & info ["m"; "min"] ~docv:"MIN" ~doc

    (* float option *)
    let max_arg =
      let doc = "Select the upper temperature limit $(docv).  \
                 This takes precedence over upper limit of a \
                 range specified in --temperature." in
      let open Arg in
      value
      & opt (some float) None
      & info ["M"; "max"] ~docv:"MAX" ~doc

    (* WT.switch option *)
    let push_arg =
      let doc = "Switch the push alarm on/off." in
      let open Arg in
      value
      & opt (some switch) ~vopt:(Some WT.On) None
      & info ["p"; "push"] ~docv:switch_docv ~doc

    (* WT.switch option *)
    let beep_arg =
      let doc = "Switch the beep alarm on/off." in
      let open Arg in
      value
      & opt (some switch) ~vopt:(Some WT.On) None
      & info ["b"; "beep"] ~docv:switch_docv  ~doc

    let term =
      let open Term in
      const
        (fun common all channels range min max push beep ->
          WT.update_channels common ~all ?range ?min ?max ?push ?beep channels)
      $ Common.term
      $ all_arg
      $ Channels.term
      $ range_arg
      $ min_arg
      $ max_arg
      $ push_arg
      $ beep_arg

    let man = [
        `S Manpage.s_description;
        `P "Change the temperature limits and associated alarms \
            on a WT Mini V3 using the HTTP API." ] @ Common.man_footer

    let cmd =
      Cmd.v (Cmd.info "alarm" ~man) term

  end

module Pitmaster : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Print the pitmaster status." ] @ Common.man_footer

    let term =
      let open Term in
      const (fun common -> WT.format_pitmasters common |> List.iter print_endline)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "pitmaster" ~man) term

  end


module Control : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Modify the pitmaster status.";
        `S Manpage.s_options;
        `P "The options --recall, --auto, --manual and --off are \
            evaluated in that order.  For example, the command";
        `Pre "  bbqcli -a 99 -o";
        `P "sets the target temperature to 99 degrees and switches \
            the pitmaster off."] @ Common.man_footer

    let channel_arg =
      let doc = "Connect the pitmaster to the channel number $(docv)." in
      let open Arg in
      value
      & opt (some int) None
      & info ["c"; "channel"] ~docv:"CH" ~doc

    let pitmaster_arg =
      let doc = "Modify the pitmaster number $(docv). \
                 This is never needed if there is only \
                 a single pitmaster with number 0." in
      let open Arg in
      value
      & opt int 0
      & info ["p"; "pitmaster"] ~docv:"PM" ~doc

    let recall_arg =
      let doc = "Switch the pitmaster back to the last active state." in
      let open Arg in
      value
      & flag
      & info ["r"; "recall"] ~doc

    let off_arg =
      let doc = "Switch the pitmaster off." in
      let open Arg in
      value
      & flag
      & info ["o"; "off"] ~doc

    let auto_arg =
      let doc = "Switch the pitmaster in auto mode with \
                 target temperature $(docv).  Negative values \
                 keep the old value unchanged." in
      let open Arg in
      value
      & opt (some float) ~vopt:(Some (-1.)) None
      & info ["a"; "auto"] ~docv:"T" ~doc

    let manual_arg =
      let doc = "Switch the pitmaster in manual mode with \
                 $(docv)% power. Negative values \
                 keep the old value unchanged." in
      let open Arg in
      value
      & opt (some int) ~vopt:(Some (-1)) None
      & info ["m"; "manual"] ~docv:"P" ~doc

    let term =
      let open Term in
      const (fun common pitmaster channel recall off auto manual ->
          WT.update_pitmaster common ?channel ~recall ~off ?auto ?manual pitmaster)
      $ Common.term
      $ pitmaster_arg
      $ channel_arg
      $ recall_arg
      $ off_arg
      $ auto_arg
      $ manual_arg

    let cmd =
      Cmd.v (Cmd.info "control" ~man) term

  end


module Info : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Echo the unformatted response to \"/info\".  According to \
            the developers, this is not meant to be parsed, but just as \
            quick feedback." ] @ Common.man_footer

    let term =
      let open Term in
      const (fun common -> WT.get_info common |> print_endline)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "info" ~man) term

  end


module Data : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Echo the parsed and pretty printed JSON response to \"/data\". \
            Currently, no processing is done.  This will change in the \
            future." ] @ Common.man_footer

    let term =
      let open Term in
      const (fun common -> WT.get_data common |> print_json)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "data" ~man) term

  end


module Settings : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Echo the parsed and pretty printed JSON response to \"/settings\". \
            Currently, no processing is done.  This will change in the \
            future." ] @ Common.man_footer

    let term =
      let open Term in
      const (fun common -> WT.get_settings common |> print_json)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "settings" ~man) term

  end


module Battery : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Print the current changing status." ] @ Common.man_footer

    let term =
      let open Term in
      const (fun common -> WT.format_battery common |> print_endline)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "battery" ~man) term

  end


module Monitor : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Continuously monitor the WLANThermo." ] @ Common.man_footer

    (* int *)
    let number_arg =
      let doc = "Stop after $(docv) measurements. \
                 A negative value or 0 will let the \
                 monitoring contine indefinitely." in
      let open Arg in
      value
      & opt int 0
      & info ["n"; "number"] ~docv:"N"  ~doc

    (* int *)
    let wait_arg =
      let doc = "Wait $(docv) seconds between measurements. \
                 A negative value or 0 will be mapped to 1." in
      let open Arg in
      value
      & opt int 10
      & info ["w"; "wait"] ~docv:"SEC"  ~doc

    type format =
      | Time
      | Date_Time
      | Seconds
    let format_list = [("time", Time); ("date-time", Date_Time); ("seconds", Seconds)]
    let format_enum = Arg.enum format_list
    let format_docv = String.concat "|" (List.map fst format_list)

    (* string option *)
    let format_arg =
      let doc = "Select the format of the timestamp.  One of
                 \"time\", \"date-time\" or \"seconds\"." in
      let open Arg in
      value
      & opt (some format_enum) ~vopt:(Some Time) None
      & info ["F"; "format"] ~docv:"FORMAT"  ~doc

    (* string option *)
    let epoch_arg =
      let doc = "Print time passed since $(docv). \
                 An empty string means now.  Otherwise it must \
                 be given in the format \"HH:MM\" or \"HH:MM:SS\"." in
      let open Arg in
      value
      & opt (some string) ~vopt:(Some "") None
      & info ["E"; "epoch"] ~docv:"TIME"  ~doc

    (* Evaluate the ~number-th power

         f (f (f ... (f initial)))

       waiting ~wait(>0) seconds between evaluations. *)

    let repeat ~wait ~number f initial =
      let wait = max 1 wait
      and number = max 0 number in
      let rec repeat' n previous =
        let state = f previous in
        if n <> 1 then
          begin
            Unix.sleep wait;
            (repeat' [@tailcall]) (max 0 (pred n)) state
          end in
      repeat' number initial

    let decode_epoch epoch =
      match String.lowercase_ascii epoch with
      | "" | "n" | "no" | "now" -> ThoTime.now ()
      | time -> ThoTime.of_string_time time

    let decode_format_epoch = function
      | (None | Some Time), None -> ThoTime.Time
      | Some Seconds, None -> ThoTime.Seconds
      | Some Date_Time, None -> ThoTime.Date_Time
      | (None | Some Time), Some epoch ->
         ThoTime.Time_since (decode_epoch epoch)
      | Some Seconds, Some epoch -> ThoTime.Seconds_since (decode_epoch epoch)
      | Some Date_Time, Some epoch ->
         prerr_endline
           (program_name ^
              ": the combination of --format=date-time with --epoch \
               makes no sense, falling back to --format=time.");
         flush stderr;
         ThoTime.Time_since (decode_epoch epoch)

    let term =
      let open Term in
      const
        (fun common channels format epoch wait number ->
          let format = decode_format_epoch (format, epoch) in
          repeat ~wait ~number (WT.monitor_temperatures ~format common channels) ([], []))
      $ Common.term
      $ Channels.term
      $ format_arg
      $ epoch_arg
      $ wait_arg
      $ number_arg

    let cmd =
      Cmd.v (Cmd.info "monitor" ~man) term

  end


module Main : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Control a WLANThermo Mini V3 on the command line \
            using the HTTP API.";
        `S Manpage.s_examples;
        `Pre "  bbqcli alarm -C 3-5 -c 9 -t 80-110 -p on";
        `P "Sets the temperature range on channels 3,4,5,9 \
            to [80,110] and switches on the push alert.";
        `Pre "  bbqcli temperature -a";
        `P "List the temperatures and limits for all channels, \
            including the limits of disconnected channels.";
        `Pre "  bbqcli monitor -w 60";
        `P "Monitor all temperatures every minute." ] @ Common.man_footer

    let cmd =
      Cmd.group
        (Cmd.info "bbqcli" ~man)
        [ Temperature.cmd;
          Alarm.cmd;
          Pitmaster.cmd;
          Control.cmd;
          Monitor.cmd;
          Battery.cmd;
          Data.cmd;
          Settings.cmd;
          Info.cmd ]

  end

let _ =
  ignore (Config.of_string "")

let () =
  exit (Cmd.eval Main.cmd)
