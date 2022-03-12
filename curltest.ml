let writer accum data =
  Buffer.add_string accum data;
  String.length data

let show result =
  print_endline (Yojson.Basic.pretty_to_string (Yojson.Basic.from_string result));
  flush stdout

let post url data =
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  let result = Buffer.create 1024
  and errorBuffer = ref "" in
  begin try
      let connection = Curl.init () in
      Curl.set_errorbuffer connection errorBuffer;
      Curl.set_writefunction connection (writer result);
      Curl.set_httpheader connection [ "Content-Type: application/json" ];
      Curl.set_postfields connection data;
      Curl.set_url connection url;
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

let get url =
  let result = Buffer.create 1024
  and errorBuffer = ref "" in
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  begin
    begin try
        let connection = Curl.init () in
	Curl.set_errorbuffer connection errorBuffer;
	Curl.set_writefunction connection (writer result);
	Curl.set_url connection url;
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

let _ =
  show (post Sys.argv.(1) {| { "foo" : "bar" } |});
  show (get Sys.argv.(2))
