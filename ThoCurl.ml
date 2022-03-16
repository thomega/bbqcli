(* ThoCurl.ml -- simple interface to curl(1) *)

type options =
  { ssl : bool;
    host : string;
    verbosity : int;
    timeout : int option }

exception Invalid_JSON of string * string

let string_to_json s =
  try
    Yojson.Basic.from_string s
  with
  | Yojson.Json_error msg -> raise (Invalid_JSON (msg, s))

let url_of_path options path =
  let protocol =
    if options.ssl then
      "https"
    else
      "http" in
  protocol ^ "://" ^ options.host ^ "/" ^ path

let fill_buffer buffer data =
  Buffer.add_string buffer data;
  String.length data

let do_curl options path extra_setup =
  let result = Buffer.create 16384
  and error_response = ref "" in
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  begin try
      let curl = Curl.init () in
      Curl.set_url curl (url_of_path options path);
      begin match options.timeout with
      | None -> ()
      | Some t -> Curl.set_timeout curl t
      end;
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

let get options path =
  do_curl options path no_extras

let get_json options path =
  get options path |> string_to_json

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
     
let post options path ?content data =
  do_curl options path (setup_post ?content data)

let post_json options path data =
  post options path ~content:JSON (Yojson.Basic.to_string data) |> string_to_json
