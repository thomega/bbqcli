(* tabulate.ml -- tabulate strings. *)

(* Pairwise combine the elements of two lists of different length,
   padding the short of the two lists, if necessary. *)
let splice op pad1 pad2 l1 l2 =
  let rec splice' acc = function
    | [], [] -> List.rev acc
    | [], l -> List.rev_append acc (List.map (fun x -> op pad1 x) l)
    | l, [] -> List.rev_append acc (List.map (fun x -> op x pad2) l)
    | h1 :: t1, h2 :: t2 ->
       splice' (op h1 h2 :: acc) (t1, t2) in
  splice' [] (l1, l2)

(* Compute the lenght of the longest string at each
   position of a list of list of strings. *)
let max_length lists =
  List.fold_left
    (splice (fun len s -> max len (String.length s)) 0 "")
    [0]
    lists

(* Pad a string with blanks to a desired length. *)
let pad_string l s =
  let len = l - String.length s in
  if len < 0 then
    invalid_arg (Printf.sprintf "pad: length(%s) > %d" s l)
  else
    s ^ String.make len ' '

(* Pad a list of strings with blanks to a desired length.
   This will fail if the list of lengths is shorter than
   the list of strings. *)
let pad_strings lenghts strings =
  splice pad_string 0 "" lenghts strings

let pad_strings_list lenghts strings_list =
  List.map (pad_strings lenghts) strings_list

let concat_padded_strings_list sep lenghts strings_list =
  List.map (fun strings -> String.concat sep (pad_strings lenghts strings)) strings_list

let strings_list sep strings_list =
  concat_padded_strings_list sep (max_length strings_list) strings_list

(*
let _ =
  List.iter
    print_endline
    (tabulate_strings_list
       "|"
       [[ "a";  "bbb"; "c"  ];
        [ "aa"; "bb";  "cccc" ]])
 *)
