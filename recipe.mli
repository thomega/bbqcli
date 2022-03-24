(* recipe_file.mli -- *)

type t = Recipe_syntax.t

val of_string : string -> t
