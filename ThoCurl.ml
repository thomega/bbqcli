(* ThoCurl.ml -- simple interface to curl(1) *)

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

let fill_buffer buffer data =
  Buffer.add_string buffer data;
  String.length data

let get ?ssl ~host path =
  let result = Buffer.create 1024
  and errorBuffer = ref "" in
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  begin try
      let connection = Curl.init () in
      Curl.set_errorbuffer connection errorBuffer;
      Curl.set_writefunction connection (fill_buffer result);
      Curl.set_url connection (url_of_path ?ssl ~host path);
      Curl.set_timeout connection 10;
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
  Curl.global_cleanup ();
  Buffer.contents result

let get_json ?ssl ~host path =
  get ?ssl ~host path |> string_to_json

let post ?ssl ~host path data =
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  let result = Buffer.create 1024
  and errorBuffer = ref "" in
  begin try
      let connection = Curl.init () in
      Curl.set_errorbuffer connection errorBuffer;
      Curl.set_writefunction connection (fill_buffer result);
      Curl.set_httpheader connection [ "Content-Type: application/json" ];
      Curl.set_postfields connection data;
      Curl.set_url connection (url_of_path ?ssl ~host path);
      Curl.set_timeout connection 10;
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
