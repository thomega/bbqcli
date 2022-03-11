open Cmdliner

let channels_arg =
  let doc = "Select the channel $(docv) (can be repeated)." in
  Arg.(value & opt_all int [] & info ["c"; "channel"] ~docv:"N" ~doc)

let channel_ranges_arg =
  let doc = "Select the channels in the range $(docv) (can be repeated)." in
  Arg.(value & opt_all (pair ~sep:'-' int int) [] & info ["r"; "range"] ~docv:"FROM-TO" ~doc)

let temperature_range_arg =
  let doc = "Select the temperature range $(docv)." in
  Arg.(value & opt (some (pair ~sep:'-' float float)) None & info ["t"; "temperature"] ~docv:"FROM-TO" ~doc)

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

let merge_integer_ranges integers ranges =
  compress (integers @ List.concat (List.map (fun (i, j) -> range i j) ranges))

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


let alarm channels channel_ranges temperature_range =
  let all_channels = merge_integer_ranges channels channel_ranges in
  Printf.printf
    "alarm of channel(s) %s set to range %s\n"
    (String.concat
       "," (List.map string_of_int all_channels))
    (match temperature_range with
     | None -> "?"
     | Some (t1, t2) -> "[" ^ string_of_float t1 ^ "," ^ string_of_float t2 ^ "]")

let alarm_term =
  Term.(const alarm $ channels_arg $ channel_ranges_arg $ temperature_range_arg)

let alarm_cmd =
  Cmd.v (Cmd.info "alarm") alarm_term


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
  let info = Cmd.info "bbqcli" in
  Cmd.group info [info_cmd; data_cmd; battery_cmd; temperature_cmd; alarm_cmd]

let () =
  exit (Cmd.eval main_cmd)
