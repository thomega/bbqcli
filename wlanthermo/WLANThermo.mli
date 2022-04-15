(* WLANThermo.ml *) (** API of the {i WLANThermo} BBQ Thermometer and Pitmaster. *)

(** We're using the JSO representation chosen by [ThoCurl]. *)
module JSON = ThoCurl.JSON

(** Request ["/data"] from the server. *)
val get_data : ThoCurl.options -> JSON.t

(** Request ["/info"] from the server.  NB: this is {i not} formatted as JSON! *)
val get_info : ThoCurl.options -> string

(** Request ["/settings"] from the server. *)
val get_settings : ThoCurl.options -> JSON.t

(** Get the battery status from the server and format it as a string. *)
val format_battery : ThoCurl.options -> string

(** [format_channels ~all server channels] formats the status of the
    [channels] on [server] as a list of strings.   Include inactive
    channels if [all] is true. *)
val format_channels : ?all:bool -> ThoCurl.options -> int list -> string list

(** [format_pitmasters server] formats the status of the active pitmasters
    on [server] as a list of strings. *)
val format_pitmasters : ThoCurl.options -> string list

(** [monitor_temperatures server ~format channels previous]
    formats the status of the active among [channels] and active pitmasters
    on [server].  If the list active channels and pitmasters has changed
    since [prev], a new header is printed.  *)
val monitor_temperatures :
  ThoCurl.options -> ?format:ThoTime.format ->
  int list -> int list * int list -> int list * int list 

(** Switching alarms on and off. *)
type switch = On | Off

(** [update_channels server ~all ~range ~min ~max ~push ~beep channels]
    updates the temperature [range] and alarm status on [channels],
    including inactive ones if [all] is [true]. *)
val update_channels :
  ThoCurl.options -> ?all:bool ->
  ?range:(float * float) -> ?min:float -> ?max:float ->
  ?push:switch -> ?beep:switch -> int list -> unit

(** [rename_channel ch name] change the name of channel [ch] to [name]. *)
val rename_channel : ThoCurl.options -> int -> string -> unit

(** [update_pitmaster server ~channel ~auto:temperature ~manual:percentage ~recall ~off pm]
    updates the pitmaster [pm].  Note that [off] overrides [manual]
    overrides [auto] overrides [recall] of the previous setting. *)
val update_pitmaster :
  ThoCurl.options -> ?channel:int -> ?auto:float -> ?manual:int ->
  recall:bool -> off:bool -> int -> unit
