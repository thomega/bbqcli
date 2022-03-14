(* ThoCurl.ml -- simple interface to curl(1) *)

let timeout = 10 (* seconds *)

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

let do_curl ?ssl ~host path extra_setup =
  let result = Buffer.create 16384
  and error_response = ref "" in
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  begin try
      let curl = Curl.init () in
      Curl.set_url curl (url_of_path ?ssl ~host path);
      Curl.set_timeout curl timeout;
      Curl.set_errorbuffer curl error_response;
      Curl.set_writefunction curl (fill_buffer result);
      extra_setup curl;
      Curl.perform curl;
      Curl.cleanup curl
    with
    | Curl.CurlException (curlcode, _code, _msg) ->
       Curl.global_cleanup ();
       begin match !error_response with
       | "" -> failwith (Curl.strerror curlcode)
       | s -> failwith s
       end
  end;
  Curl.global_cleanup ();
  Buffer.contents result

let no_extras _ = ()

let get ?ssl ~host path =
  do_curl ?ssl ~host path no_extras

let get_json ?ssl ~host path =
  get ?ssl ~host path |> string_to_json

type content =
  | JSON

let content_to_string = function
  | JSON -> "application/json"

(* NB: [Curl.set_post curl true] is implicit in [Curl.set_postfields].
   It is only needed if the POST data is read with [Curl.set_readfunction].  *)
let setup_post ?content data =
  (fun curl ->
    begin match content with
    | None -> ()
    | Some c ->
       Curl.set_httpheader curl [ "Content-Type: " ^ content_to_string c ];
    end;
    Curl.set_postfields curl data)
     
let post ?ssl ~host path ?content data =
  do_curl ?ssl ~host path (setup_post ?content data)

let post_json ?ssl ~host path data =
  post ?ssl ~host path ~content:JSON (Yojson.Basic.to_string data) |> string_to_json
