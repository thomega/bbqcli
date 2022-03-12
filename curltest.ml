let writer accum data =
  Buffer.add_string accum data;
  String.length data

let showContent content =
  print_endline
    (Yojson.Basic.pretty_to_string
       (Yojson.Basic.from_string (Buffer.contents content)));
  flush stdout

let showInfo connection =
  Printf.printf "Time: %f\nURL: %s\n"
    (Curl.get_totaltime connection)
    (Curl.get_effectiveurl connection)

let post url data =
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  begin
    let result = Buffer.create 1024
    and errorBuffer = ref "" in
    try
      let connection = Curl.init () in
	Curl.set_errorbuffer connection errorBuffer;
	Curl.set_writefunction connection (writer result);
        Curl.set_httpheader connection [ "Content-Type: application/json" ];
        Curl.set_postfields connection data;
	Curl.set_url connection url;
	Curl.perform connection;
	showContent result;
	showInfo connection;
	Curl.cleanup connection
    with
      | Curl.CurlException (curlcode, code, msg) ->
	 Printf.eprintf
           "Error: %s (err=%s, code=%d, %s)\n"
           !errorBuffer (Curl.strerror curlcode) code msg
      | Failure msg ->
	  Printf.fprintf stderr "Caught exception: %s\n" msg
  end;
  Curl.global_cleanup ()

let get url =
  Curl.global_init Curl.CURLINIT_GLOBALALL;
  begin
    let result = Buffer.create 1024
    and errorBuffer = ref "" in
    try
      let connection = Curl.init () in
	Curl.set_errorbuffer connection errorBuffer;
	Curl.set_writefunction connection (writer result);
	Curl.set_url connection url;
	Curl.perform connection;
	showContent result;
	showInfo connection;
	Curl.cleanup connection
    with
      | Curl.CurlException (curlcode, code, msg) ->
	 Printf.eprintf
           "Error: %s (err=%s, code=%d, %s)\n"
           !errorBuffer (Curl.strerror curlcode) code msg
      | Failure msg ->
	  Printf.fprintf stderr "Caught exception: %s\n" msg
  end;
  Curl.global_cleanup ()

let _ =
  post Sys.argv.(1) {| { "foo" : "bar" } |};
  get Sys.argv.(2)
