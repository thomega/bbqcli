(* ThoList.mli *) (** Useful stuff missing from [List] *)

(** [range ~stride:s n m] returns [[n; n+s; n+2s; m - (n-m) mod s]]$ *)
val range : ?stride:int -> int -> int -> int list

(** [uniq list] compresses repeated elements in the {e sorted} [list].
   Identity is determined using the polymorphic equality function
   [Stdlib.(=)]. *)
val uniq : 'a list -> 'a list

(** [compress list] sorts the list and removes duplicates.
    The implementation is asympototically inefficient,
    but OK if we're dealing with short lists. *)
val compress : 'a list -> 'a list

(** [merge_integer_ranges integers ranges] form the set union of the 
    integers in the lists [integers] with the ranges of integers described
    by the pairs [ranges].  E.g.
    [merge_integer_ranges [[3];[7;9]] [[(1,1)]; [(9,11); (42,41)]]]
    returns [[1;3;7;9;10;11]]. *)
val merge_integer_ranges : int list list -> (int * int) list list -> int list

(** [splice op p1 p2 l1 l2] combines pairwise the elements of the
    lists [l1] and [l2].  If the lists are of different length, the shorter
    of the two is padded with [p1] or [p2].  E.g.
    [splice (+) 0 0 [1;2;3] [10,20]] returns [[11;22;3]]. *)
val splice : ('a -> 'b -> 'c) -> 'a -> 'b -> 'a list -> 'b list -> 'c list
