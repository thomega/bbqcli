(* ThoList.ml -- useful stuff missing from List *)

(* NOT tail recursive, due to the cons! *)
let range ?(stride=1) n1 n2 =
  if stride <= 0 then
    invalid_arg "range: stride <= 0"
  else
    let rec range' n =
      if n > n2 then
        []
      else
        n :: range' (n + stride) in
    range' n1

(* NOT tail recursive, due to the cons! *)
let rec uniq' x = function
  | [] -> []
  | x' :: rest ->
     if x' = x then
       uniq' x rest
     else
       x' :: uniq' x' rest

let uniq = function
  | [] -> []
  | x :: rest -> x :: uniq' x rest

(* Asympototically inefficient, but OK if we're dealing with short lists. *)
let compress l =
  uniq (List.sort Stdlib.compare l)

let expand_range (i, j) =
  range i j

let expand_ranges =
  List.map expand_range

let merge_integer_ranges integer_lists ranges =
  compress (List.concat (integer_lists @ expand_ranges (List.concat ranges)))

(* Pairwise combine the elements of two lists of different length,
   padding the short of the two lists, if necessary. *)
let splice op pad1 pad2 l1 l2 =
  let rec splice' acc = function
    | [], [] -> List.rev acc
    | [], l -> List.rev_append acc (List.map (fun x -> op pad1 x) l)
    | l, [] -> List.rev_append acc (List.map (fun x -> op x pad2) l)
    | h1 :: t1, h2 :: t2 ->
       (splice' [@tailcall]) (op h1 h2 :: acc) (t1, t2) in
  splice' [] (l1, l2)
