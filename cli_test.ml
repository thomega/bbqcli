let get_info () =
  print_endline "info"

let data () =
  print_endline "data"

let battery () =
  print_endline "battery"

open Cmdliner

let info_term =
  Term.(const get_info $ const ())

let data_term =
  Term.(const data $ const ())

let battery_term =
  Term.(const battery $ const ())

let info_cmd =
  Cmd.v (Cmd.info "info") info_term

let data_cmd =
  Cmd.v (Cmd.info "data") data_term

let battery_cmd =
  Cmd.v (Cmd.info "battery") battery_term

let main_cmd =
  let info = Cmd.info "bbqcli" in
  Cmd.group info [info_cmd; data_cmd; battery_cmd]

let () =
  exit (Cmd.eval main_cmd)
