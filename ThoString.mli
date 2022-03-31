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
