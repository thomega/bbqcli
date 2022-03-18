(* bbqcli.ml -- CLI etc. for the WLANThermo API *)

let host_default = "wlanthermo"

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
  & opt bool ~vopt:true false
  & info ["a"; "all"] ~docv:"true/false" ~doc

module Channels : sig val term : int list Term.t end =
  struct

    (* int list list *)
    let channels_arg =
      let doc = "Select the channel(s) $(docv) (can be repeated)." in
      let open Arg in
      value
      & opt_all (list int) []
      & info ["c"; "channel"; "ch"] ~docv:"N[,M...]" ~doc

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
      let doc = "Wait $(docv) seconds between measurements." in
      let open Arg in
      value
      & opt int 10
      & info ["w"; "wait"] ~docv:"SEC"  ~doc

    let loop ~wait ~number f =
      let rec loop' () n =
        f ();
        if n <> 1 then
          begin
            Unix.sleep wait;
            (loop' [@tailcall]) () (max 0 (pred n))
          end in
      loop' () number

    let monitor common () =
      ignore common;
      Printf.printf "monitor ...\n";
      flush stdout

    let term =
      let open Term in
      const
        (fun common wait number ->
          loop ~wait ~number:(max 0 number) (monitor common))
      $ Common.term
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
        `Pre "bbqcli alarm -c 9 -t 80-110 -p on";
        `P "Sets the temperature range on channel 9 to [80,110] \
            and switches on the push alert.";
        `Pre "bbqcli temperature -a";
        `P "List the temperatures and limits for all channels, \
            including the limits of disconnected channels."] @ Common.man_footer

    let cmd =
      Cmd.group
        (Cmd.info "bbqcli" ~man)
        [ Temperature.cmd;
          Alarm.cmd;
          Pitmaster.cmd;
          Monitor.cmd;
          Battery.cmd;
          Data.cmd;
          Settings.cmd;
          Info.cmd ]

  end

let () =
  exit (Cmd.eval Main.cmd)
