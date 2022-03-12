(* bbqcli.ml -- CLI etc. for the WLANThermo API *)

let host_default = "wlanthermo"

let my_name = Sys.argv.(0)

let separator = String.make 72 '='

let print_json j =
  Yojson.Basic.pretty_to_string j |> print_endline

(* with
   | ThoCurl.Invalid_JSON (msg, s) ->
      Printf.printf "Invalid JSON:\n%s\n%s\n%s\n%s\n" msg separator s separator
 *)

open Cmdliner

let man_footer =
  [ `S Manpage.s_files;
    `P "tba.";
    `S Manpage.s_authors;
    `P "Thorsten Ohl <ohl@physik.uni-wuerzburg.de>.";
    `S Manpage.s_bugs;
    `P "Report bugs to <ohl@physik.uni-wuerzburg.de>." ]

let ssl_arg =
  let doc = "Use SSL to connect to the host." in
  let env = Cmd.Env.info "WLANTHERMO_SSL" in
  let open Arg in
  value
  & opt bool ~vopt:true false
  & info ["s"; "ssl"] ~docv:"true/false" ~doc ~env

let host_arg =
  let doc = "Connect to the host $(docv)." in
  let env = Cmd.Env.info "WLANTHERMO_HOST" in
  let open Arg in
  value
  & opt string host_default
  & info ["H"; "host"] ~docv:"HOST" ~doc ~env

let envs =
  [ Cmd.Env.info "WLANTHERMO_HOST" ~doc:"Overrides the default hostname.";
    Cmd.Env.info "WLANTHERMO_SSL" ~doc:"If set, use https instead of htpp." ]

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

type switch = On | Off

let switch_to_string = function
  | On -> "on"
  | Off -> "off"

(* Put the long form of equivalent options last so that they are
   used for the description of the default in the manpage. *)
let switch = Arg.enum [("+", On); ("on", On); ("-", Off); ("off", Off)]

let switch_docv = "on|+|off|-"


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


module type Unit_Cmd =
  sig
    val cmd : unit Cmd.t
  end

module Temperature : Unit_Cmd =
  struct

    let f channels ranges =
      let all_channels = Utils.merge_integer_ranges channels ranges in
      Printf.printf
        "temperature of channel(s) %s\n"
        (String.concat
           "," (List.map string_of_int all_channels));
      match all_channels with
      | [] -> WLANThermo.print_temperatures ()
      | ch_list -> List.iter WLANThermo.print_temperature ch_list

    let term =
      Term.(const f $ channels_arg $ channel_ranges_arg)

    let cmd =
      Cmd.v (Cmd.info "temperature") term

end


module Alarm : Unit_Cmd =
  struct

    let f channels channel_ranges temperature_range push beep =
      let all_channels = Utils.merge_integer_ranges channels channel_ranges in
      Printf.printf
        "alarm of channel(s) %s set to range %s:%s%s\n"
        (String.concat "," (List.map string_of_int all_channels))
        (match temperature_range with
         | None -> "?"
         | Some (t1, t2) -> "[" ^ string_of_float t1 ^ "," ^ string_of_float t2 ^ "]")
        (match push with
         | None -> ""
         | Some s -> " " ^ switch_to_string s ^ "(push)")
        (match beep with
         | None -> ""
         | Some s -> " " ^ switch_to_string s ^ "(beep)")

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
      & opt (some switch) ~vopt:(Some On) None
      & info ["p"; "push"] ~docv:switch_docv ~doc

    let beep_alarm_arg =
      let doc = "Switch the beep alarm on/off." in
      let open Arg in
      value
      & opt (some switch) ~vopt:(Some On) None
      & info ["b"; "beep"] ~docv:switch_docv  ~doc

    let term =
      let open Term in
      const f
      $ channels_arg
      $ channel_ranges_arg
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

    let f () =
      ThoCurl.get "info" |> print_endline

    let term =
      Term.(const f $ const ())

    let cmd =
      Cmd.v (Cmd.info "info") term

  end


module Data : Unit_Cmd =
  struct

    let f () =
      ThoCurl.get_json "data" |> print_json

    let term =
      Term.(const f $ const ())

    let cmd =
      Cmd.v (Cmd.info "data") term

  end


module Settings : Unit_Cmd =
  struct

    let f () =
      ThoCurl.get_json "settings" |> print_json

    let term =
      Term.(const f $ const ())

    let cmd =
      Cmd.v (Cmd.info "settings") term
  end


module Battery : Unit_Cmd =
  struct

    let f ssl host =
      WLANThermo.print_battery ~ssl ~host ()

    let term =
      Term.(const f $ ssl_arg $ host_arg)

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
  let info = Cmd.info "bbqcli" ~man ~envs in
  Cmd.group info [Alarm.cmd; Temperature.cmd; Battery.cmd;
                  Data.cmd; Settings.cmd; Info.cmd]

let () =
  exit (Cmd.eval main_cmd)
