(* ThoString.mli *) (** Useful stuff missing from [String]. *)

(** [align_string_lists sep strings_list] returns a list of strings
    with all the strings in each list of strings aligned left at the
    same column.  Inserts [sep] between columns and the lists of strings
    need not have the same length. E.g.
    [align_string_lists "|" [["a"; "bb"]; ["aa"; "b"; "c"]] |> List.iter print_endline]
    prints
{v
a |bb|
aa|b |c
v} *)
val align_string_lists : string -> string list list -> string list

(** [contains_any chars s] is [true] iff any of the characters in [chars]
    is contained in the string [s]. *)
val contains_any : char list -> string -> bool

(** Add a leading and a trailong double quote, iff the string contains
    whitspace.  This is incomplete, because it should also handle
    included quotes and escaped characters.  *)
val quote_string_if_necessary : string -> string
