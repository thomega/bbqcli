(* ThoCurl.ml -- simple interface to curl(1) *)

let curl_path = "curl"
let host_default = "wlanthermo"

let url_of_path ?(ssl=false) ?(host=host_default) path =
  let protocol =
    if ssl then
      "https"
    else
      "http" in
  protocol ^ "://" ^ host ^ "/" ^ path

let string_from_channel ic =
  let b = Buffer.create 1024 in
  try
    while true do
      Buffer.add_channel b ic 1024
    done;
    Buffer.contents b
  with
  | End_of_file -> Buffer.contents b

let get ?ssl ?host path =
  let output =
    Unix.open_process_args_in
      curl_path
      [|curl_path; "-s"; "-X"; "GET"; url_of_path ?ssl ?host path|] in
  let response = string_from_channel output in
  close_in output;
  response

let post ?ssl ?host path data =
  let output, input =
    Unix.open_process_args
      curl_path
      [|curl_path; "-s"; "-X"; "POST"; url_of_path ?ssl ?host path|] in
  output_string input data;
  close_out input;
  let response = string_from_channel output in
  close_in output;
  response

let request ?ssl ?host ?data path =
  match data with
  | None | Some "" -> get ?ssl ?host path
  | Some data -> post ?ssl ?host path data
