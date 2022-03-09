(* wlanthermo.ml -- CLI etc. for the WLANThermo API *)

let curl_path = "curl"
              
let curl () =
  let output, input =
    Unix.open_process_args
      curl_path
      [|curl_path; "-s"; "-X"; "GET"; "http://wlanthermo/settings"|] in
  close_out input;
  let response = input_line output in
  close_in output;
  response

let _ =
  print_endline (curl ());
  ()

