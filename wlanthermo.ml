(* wlanthermo.ml -- CLI etc. for the WLANThermo API *)

let curl_path = "curl"

let string_from_channel ic =
  let b = Buffer.create 1024 in
  try
    while true do
      Buffer.add_channel b ic 1024
    done;
    Buffer.contents b
  with
  | End_of_file -> Buffer.contents b

let curl_get url =
  let output =
    Unix.open_process_args_in
      curl_path
      [|curl_path; "-s"; "-X"; "GET"; url|] in
  let response = string_from_channel output in
  close_in output;
  response

let curl_post data url =
  let output, input =
    Unix.open_process_args
      curl_path
      [|curl_path; "-s"; "-X"; "POST"; url|] in
  output_string input data;
  close_out input;
  let response = string_from_channel output in
  close_in output;
  response

let curl ?data url =
  match data with
  | None | Some "" -> curl_get url
  | Some data -> curl_post data url

let _ =
  print_endline (curl ~data:"" "http://wlanthermo/settings");
  ()

