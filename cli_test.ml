open Cmdliner

let common_man =
  [ `S Manpage.s_files;
    `P "tba.";
    `S Manpage.s_authors;
    `P "Thorsten Ohl <ohl@physik.uni-wuerzburg.de>.";
    `S Manpage.s_bugs;
    `P "Report bugs to <ohl@physik.uni-wuerzburg.de>." ]

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

(* (float * float) option *)
let temperature_range_arg =
  let doc = "Select the temperature range $(docv)." in
  let open Arg in
  value
  & opt (some (pair ~sep:'-' float float)) None
  & info ["t"; "temperature"; "temp"] ~docv:"FROM-TO" ~doc

type switch = On | Off
let switch_to_string = function
  | On -> "on"
  | Off -> "off"

let docv_switch = "on|off|+|-"

let switch =
  let docv = docv_switch in
  let parse s =
    match String.lowercase_ascii s with
    | "on" | "+" -> Ok On
    | "off" | "-" -> Ok Off
    | _ -> Error (`Msg ("invalid argument: " ^ s ^ " (one of {" ^ docv ^ "} or empty)"))
  and print ppf p = Format.fprintf ppf "%s" (switch_to_string p) in
  Arg.conv ~docv (parse, print)

let push_alarm_arg =
  let doc = "Switch the push alarm on/off." in
  let open Arg in
  value
  & opt (some switch) ~vopt:(Some On) None
  & info ["p"; "push"] ~docv:docv_switch ~doc

let beep_alarm_arg =
  let doc = "Switch the beep alarm on/off." in
  let open Arg in
  value
  & opt (some switch) ~vopt:(Some On) None
  & info ["b"; "beep"] ~docv:docv_switch  ~doc

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

let compress l =
  uniq (List.sort Stdlib.compare l)

let expand_range (i, j) =
  range i j

let expand_ranges =
  List.map expand_range

let merge_integer_ranges integer_lists ranges =
  compress (List.concat (integer_lists @ expand_ranges (List.concat ranges)))

let temperature channels ranges =
  let all_channels = merge_integer_ranges channels ranges in
  Printf.printf
    "temperature of channel(s) %s\n"
    (String.concat
       "," (List.map string_of_int all_channels))

let temperature_term =
  Term.(const temperature $ channels_arg $ channel_ranges_arg)

let temperature_cmd =
  Cmd.v (Cmd.info "temperature") temperature_term

let alarm channels channel_ranges temperature_range push beep =
  let all_channels = merge_integer_ranges channels channel_ranges in
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

let alarm_term =
  let open Term in
  const alarm
  $ channels_arg
  $ channel_ranges_arg
  $ temperature_range_arg
  $ push_alarm_arg
  $ beep_alarm_arg

let alarm_cmd =
  let man = [
      `S Manpage.s_description;
      `P "Change the temperature limits and associated alarms \
          on a WLANThermo Mini V3 using the HTTP API." ] @ common_man in
  Cmd.v (Cmd.info "alarm" ~man) alarm_term


let get_info () =
  print_endline "info"

let info_term =
  Term.(const get_info $ const ())

let info_cmd =
  Cmd.v (Cmd.info "info") info_term


let data () =
  print_endline "data"

let data_term =
  Term.(const data $ const ())

let data_cmd =
  Cmd.v (Cmd.info "data") data_term


let battery () =
  print_endline "battery"

let battery_term =
  Term.(const battery $ const ())

let battery_cmd =
  Cmd.v (Cmd.info "battery") battery_term


let main_cmd =
  let man = [
      `S Manpage.s_description;
      `P "Control a WLANThermo Mini V3 on the command line \
          using the HTTP API."; ] @ common_man in
  let info = Cmd.info "bbqcli" ~man in
  Cmd.group info [info_cmd; data_cmd; battery_cmd; temperature_cmd; alarm_cmd]

let () =
  exit (Cmd.eval main_cmd)
