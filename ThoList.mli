(* ThoList.mli -- useful stuff missing from List *)

(* [range s n m] is $[\ocwlowerid{n}; \ocwlowerid{n}+\ocwlowerid{s};
   \ocwlowerid{n}+2\ocwlowerid{s};\ldots;
   \ocwlowerid{m} - ((\ocwlowerid{m}-\ocwlowerid{n})\mod s)]$ *)
val range : ?stride:int -> int -> int -> int list

(* Compress identical elements in a sorted list.  Identity
   is determined using the polymorphic equality function
   [Stdlib.(=)]. *)
val uniq : 'a list -> 'a list

(* Sort the list and remove duplicates (asympototically inefficient,
   but OK if we're dealing with short lists). *)
val compress : 'a list -> 'a list

val merge_integer_ranges : int list list -> (int * int) list list -> int list

val splice : ('a -> 'b -> 'c) -> 'a -> 'b -> 'a list -> 'b list -> 'c list
