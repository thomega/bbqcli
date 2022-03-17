(* bbqd.ml -- daemon for the WLANThermo API *)

module WT = WLANThermo

open Cmdliner

module type Unit_Cmd =
  sig
    val cmd : unit Cmd.t
  end

module Log : Unit_Cmd =
  struct

    let term =
      let open Term in
      const (fun _common -> ())
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "log") term

  end

let main_cmd =
  let open Manpage in
  let man = [
      `S s_description;
      `P "Control a WLANThermo Mini V3 using the HTTP API.";
      `S s_examples;
      `Pre "bbqcli -c 9 -r 80-110 -p on"] @ Common.man_footer in
  let info = Cmd.info "bbqcli" ~man in
  Cmd.group info [Log.cmd]

let () =
  exit (Cmd.eval main_cmd)
