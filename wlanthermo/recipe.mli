(* recipe.mli *) (** Interpret recipes from a file. *)

(** There is no documentation here, because things are very
    much in flux ... *)

type t = Recipe_syntax.t

val of_string : string -> t
val of_channel : string -> in_channel -> t
val of_file : string -> t

val pretty_print : t -> unit
