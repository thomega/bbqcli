(* tabulate.mli -- tabulate strings. *)

val strings_list : string -> string list list -> string list

(* For a more general list library: *)
val splice : ('a -> 'b -> 'c) -> 'a -> 'b -> 'a list -> 'b list -> 'c list
