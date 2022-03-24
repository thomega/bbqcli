(* recipe_file.mli -- *)

type t = Recipe_syntax.t

val of_string : string -> t
val of_channel : string -> in_channel -> t
val of_file : string -> t

val pretty_print : t -> unit
