(* ThoCurl.ml -- simple interface to curl(1) *)

let curl_path = "curl"

exception Invalid_JSON of string * string

let string_to_json s =
  try
    Yojson.Basic.from_string s
  with
  | Yojson.Json_error msg -> raise (Invalid_JSON (msg, s))

let url_of_path ?(ssl=false) ~host path =
  let protocol =
    if ssl then
      "https"
    else
      "http" in
  protocol ^ "://" ^ host ^ "/" ^ path

(*
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

let get ?ssl ~host path =
  let output =
    Unix.open_process_args_in
      curl_path
      [|curl_path; "-s"; "-X"; "GET"; url_of_path ?ssl ~host path|] in
  string_from_channel_and_close output
 *)

let writer accum data =
  Buffer.add_string accum data;
  String.length data

let get ?ssl ~host path =
  let result = Buffer.create 1024
  and errorBuffer = ref "" in
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  begin
    begin try
        let connection = Curl.init () in
	Curl.set_errorbuffer connection errorBuffer;
	Curl.set_writefunction connection (writer result);
	Curl.set_url connection (url_of_path ?ssl ~host path);
	Curl.perform connection;
	Curl.cleanup connection
      with
      | Curl.CurlException (curlcode, code, msg) ->
	 Printf.eprintf
           "Error: %s (err=%s, code=%d, %s)\n"
           !errorBuffer (Curl.strerror curlcode) code msg
      | Failure msg ->
	  Printf.fprintf stderr "Caught exception: %s\n" msg
    end;
  end;
  Curl.global_cleanup ();
  Buffer.contents result

let get_json ?ssl ~host path =
  get ?ssl ~host path |> string_to_json

(*
let post_or_patch_long ?ssl ~host ~request path data =
  let output, input =
    Unix.open_process_args
      curl_path
      [|curl_path; "-s"; "-X"; request; url_of_path ?ssl ~host path;
        "-H"; "Content-Type: application/json"; "-d"; "@-"|] in
  output_string input data;
  close_out input;
  string_from_channel_and_close output

let post_or_patch ?ssl ~host ~request path data =
  let output =
    Unix.open_process_args_in
      curl_path
      [|curl_path; "-s"; "-X"; request; url_of_path ?ssl ~host path;
        "-H"; "Content-Type: application/json"; "-d"; data|] in
  string_from_channel_and_close output

let post ?ssl ~host path data =
  post_or_patch ?ssl ~host ~request:"POST" path data
 *)

let post ?ssl ~host path data =
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  let result = Buffer.create 1024
  and errorBuffer = ref "" in
  begin try
      let connection = Curl.init () in
      Curl.set_errorbuffer connection errorBuffer;
      Curl.set_writefunction connection (writer result);
      Curl.set_httpheader connection [ "Content-Type: application/json" ];
      Curl.set_postfields connection data;
      Curl.set_url connection (url_of_path ?ssl ~host path);
      Curl.perform connection;
      Curl.cleanup connection;
    with
    | Curl.CurlException (curlcode, code, msg) ->
       Printf.eprintf
         "Error: %s (err=%s, code=%d, %s)\n"
         !errorBuffer (Curl.strerror curlcode) code msg
    | Failure msg ->
       Printf.fprintf stderr "Caught exception: %s\n" msg
  end;
  Curl.global_cleanup ();
  Buffer.contents result

let post_json ?ssl ~host path data =
  post ?ssl ~host path (Yojson.Basic.to_string data) |> string_to_json

(*
let patch ?ssl ~host path data =
  post_or_patch ?ssl ~host ~request:"PATCH" path data

let patch_json ?ssl ~host path data =
  patch ?ssl ~host path (Yojson.Basic.to_string data) |> string_to_json
 *)
