(* wlanthermo.ml -- CLI etc. for the WLANThermo API *)

let host_default = "wlanthermo"

let print_json s =
  let json = Yojson.Safe.from_string s in
  Format.printf "%s\n" (Yojson.Safe.pretty_to_string json)

let _ =
  print_json (ThoCurl.curl "settings")
