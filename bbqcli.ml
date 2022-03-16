(* bbqcli.ml -- CLI etc. for the WLANThermo API *)

let host_default = "wlanthermo"

let print_json j =
  Yojson.Basic.pretty_to_string j |> print_endline

open Cmdliner

let man_footer =
  [ `S Manpage.s_files;
    `P "None, so far.";
    `S Manpage.s_authors;
    `P "Thorsten Ohl <ohl@physik.uni-wuerzburg.de>.";
    `S Manpage.s_bugs;
    `P "Report bugs to <ohl@physik.uni-wuerzburg.de>." ]


module Common : sig val term : ThoCurl.options Term.t end =
  struct

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

module type Utils =
  sig
    val merge_integer_ranges : int list list -> (int * int) list list -> int list
  end

module Utils : Utils =
  struct

    (* From ThoList: *)
    let range ?(stride=1) n1 n2 =
      if stride <= 0 then
        invalid_arg "range: stride <= 0"
      else
        let rec range' n =
          if n > n2 then
            []
          else
            n :: range' (n + stride) in
        range' n1

    (* From ThoList: *)
    let rec uniq' x = function
      | [] -> []
      | x' :: rest ->
         if x' = x then
           uniq' x rest
         else
           x' :: uniq' x' rest

    let uniq = function
      | [] -> []
      | x :: rest -> x :: uniq' x rest

    (* Asympototically inefficient, but we're dealing with short
       lists here. *)
    let compress l =
      uniq (List.sort Stdlib.compare l)

    let expand_range (i, j) =
      range i j

    let expand_ranges =
      List.map expand_range

    let merge_integer_ranges integer_lists ranges =
      compress (List.concat (integer_lists @ expand_ranges (List.concat ranges)))

  end


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
          Utils.merge_integer_ranges channels channel_ranges)
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
      Printf.printf
        "temperature of channel(s) %s\n"
        (String.concat "," (List.map string_of_int channels));
      match channels with
      | [] -> WLANThermo.format_temperatures ?all common |> List.iter print_endline
      | ch_list ->
         ch_list |> List.map (WLANThermo.format_temperature common) |> List.iter print_endline

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

(* Put the long form of equivalent options last so that they are
   used for the description of the default in the manpage. *)
let switch =
  let open WLANThermo in
  Arg.enum [("+", On); ("on", On); ("-", Off); ("off", Off)]

let switch_docv = "on|+|off|-"

module Alarm : Unit_Cmd =
  struct

    (* (float * float) option *)
    let temperature_range_arg =
      let doc = "Select the temperature range $(docv)." in
      let open Arg in
      value
      & opt (some (pair ~sep:'-' float float)) None
      & info ["t"; "temperature"; "temp"] ~docv:"FROM-TO" ~doc

    let push_alarm_arg =
      let doc = "Switch the push alarm on/off." in
      let open Arg in
      value
      & opt (some switch) ~vopt:(Some WLANThermo.On) None
      & info ["p"; "push"] ~docv:switch_docv ~doc

    let beep_alarm_arg =
      let doc = "Switch the beep alarm on/off." in
      let open Arg in
      value
      & opt (some switch) ~vopt:(Some WLANThermo.On) None
      & info ["b"; "beep"] ~docv:switch_docv  ~doc

    let term =
      let open Term in
      const
        (fun common all channels temperature_range push beep ->
          WLANThermo.update_channel ~all common channels temperature_range push beep)
      $ Common.term
      $ all_arg
      $ Channels.term
      $ temperature_range_arg
      $ push_alarm_arg
      $ beep_alarm_arg

    let cmd =
      let man = [
          `S Manpage.s_description;
          `P "Change the temperature limits and associated alarms \
              on a WLANThermo Mini V3 using the HTTP API." ] @ man_footer in
      Cmd.v (Cmd.info "alarm" ~man) term

  end


module Info : Unit_Cmd =
  struct

    let term =
      let open Term in
      const (fun common -> WLANThermo.info common |> print_endline)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "info") term

  end


module Data : Unit_Cmd =
  struct

    let term =
      let open Term in
      const (fun common -> WLANThermo.data common |> print_json)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "data") term

  end


module Settings : Unit_Cmd =
  struct

    let term =
      let open Term in
      const (fun common -> WLANThermo.settings common |> print_json)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "settings") term
  end


module Battery : Unit_Cmd =
  struct

    let term =
      let open Term in
      const (fun common -> WLANThermo.format_battery common |> print_endline)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "battery") term

  end


let main_cmd =
  let open Manpage in
  let man = [
      `S s_description;
      `P "Control a WLANThermo Mini V3 on the command line \
          using the HTTP API.";
      `S s_examples;
      `Pre "bbqcli -c 9 -r 80-110 -p on"] @ man_footer in
  let info = Cmd.info "bbqcli" ~man in
  Cmd.group info [Alarm.cmd; Temperature.cmd; Battery.cmd;
                  Data.cmd; Settings.cmd; Info.cmd]

let () =
  exit (Cmd.eval main_cmd)
