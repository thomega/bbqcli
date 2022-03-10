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

let string_from_channel_and_close ic =
  let s = string_from_channel ic in
  close_in ic;
  s

let get ?ssl ?host path =
  let output =
    Unix.open_process_args_in
      curl_path
      [|curl_path; "-s"; "-X"; "GET"; url_of_path ?ssl ?host path|] in
  string_from_channel_and_close output

let post_or_patch_long ?ssl ?host ~request path data =
  let output, input =
    Unix.open_process_args
      curl_path
      [|curl_path; "-s"; "-X"; request; url_of_path ?ssl ?host path;
        "-H"; "Content-Type: application/json"; "-d"; "@-"|] in
  output_string input data;
  close_out input;
  string_from_channel_and_close output

let post_or_patch ?ssl ?host ~request path data =
  let output =
    Unix.open_process_args_in
      curl_path
      [|curl_path; "-s"; "-X"; request; url_of_path ?ssl ?host path;
        "-H"; "Content-Type: application/json"; "-d"; data|] in
  string_from_channel_and_close output

let post ?ssl ?host path data =
  post_or_patch ?ssl ?host ~request:"POST" path data

let patch ?ssl ?host path data =
  post_or_patch ?ssl ?host ~request:"PATCH" path data
