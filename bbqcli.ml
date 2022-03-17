(* bbqcli.ml -- CLI etc. for the WLANThermo API *)

module WT = WLANThermo

let print_json j =
  Yojson.Basic.pretty_to_string j |> print_endline

open Cmdliner

let all_arg =
  let doc = "Include the inactive channels." in
  let open Arg in
  value
  & opt bool ~vopt:true false
  & info ["a"; "all"] ~docv:"true/false" ~doc

module Channels : sig val term : int list Term.t end =
  struct

    (* int list list *)
    let channels_arg =
      let doc = "Select the channel(s) $(docv) (can be repeated)." in
      let open Arg in
      value
      & opt_all (list int) []
      & info ["c"; "channel"; "ch"] ~docv:"N[,M...]" ~doc

    (* (int * int) list list *)
    let channel_ranges_arg =
      let doc = "Select the channels in the range $(docv) (can be repeated)." in
      let open Arg in
      value
      & opt_all (list (pair ~sep:'-' int int)) []
      & info ["C"; "channels"] ~docv:"FROM-TO" ~doc

    let term =
      let open Term in
      const
        (fun channels channel_ranges ->
          ThoList.merge_integer_ranges channels channel_ranges)
      $ channels_arg
      $ channel_ranges_arg

  end


module type Unit_Cmd =
  sig
    val cmd : unit Cmd.t
  end

module Temperature : Unit_Cmd =
  struct

    let print_temperatures ?all common channels =
      Printf.printf
        "temperature of channel(s) %s\n"
        (String.concat "," (List.map string_of_int channels));
      match channels with
      | [] -> WT.format_channels ?all common |> List.iter print_endline
      | ch_list ->
         ch_list |> List.map (WT.format_channel common) |> List.iter print_endline

    let term =
      let open Term in
      const
        (fun common all channels ->
          print_temperatures ~all common channels)
      $ Common.term
      $ all_arg
      $ Channels.term

    let cmd =
      Cmd.v (Cmd.info "temperature") term

end

module Alarm : Unit_Cmd =
  struct

    (* Put the long form of equivalent options last so that they are
       used for the description of the default in the manpage. *)
    let switch_list = [("+", WT.On); ("on", WT.On); ("-", WT.Off); ("off", WT.Off)]
    let switch = Arg.enum switch_list
    let switch_docv = String.concat "|" (List.map fst switch_list)

    (* (float * float) option *)
    let range_arg =
      let doc = "Select the temperature range $(docv)." in
      let open Arg in
      value
      & opt (some (pair ~sep:'-' float float)) None
      & info ["t"; "temperature"; "temp"] ~docv:"FROM-TO" ~doc

    let push_arg =
      let doc = "Switch the push alarm on/off." in
      let open Arg in
      value
      & opt (some switch) ~vopt:(Some WT.On) None
      & info ["p"; "push"] ~docv:switch_docv ~doc

    let beep_arg =
      let doc = "Switch the beep alarm on/off." in
      let open Arg in
      value
      & opt (some switch) ~vopt:(Some WT.On) None
      & info ["b"; "beep"] ~docv:switch_docv  ~doc

    let term =
      let open Term in
      const
        (fun common all channels range push beep ->
          WT.update_channels common ~all range push beep channels)
      $ Common.term
      $ all_arg
      $ Channels.term
      $ range_arg
      $ push_arg
      $ beep_arg

    let man = [
        `S Manpage.s_description;
        `P "Change the temperature limits and associated alarms \
            on a WT Mini V3 using the HTTP API." ] @ Common.man_footer

    let cmd =
      Cmd.v (Cmd.info "alarm" ~man) term

  end

module Pitmaster : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Print the pitmaster status." ] @ Common.man_footer

    let term =
      let open Term in
      const (fun common -> WT.format_pitmasters common |> List.iter print_endline)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "pitmaster" ~man) term

  end


module Info : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Echo the unformatted response to \"/info\".  According to \
            the developers, this is not meant to be parsed, but just as \
            quick feedback." ] @ Common.man_footer

    let term =
      let open Term in
      const (fun common -> WT.info common |> print_endline)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "info" ~man) term

  end


module Data : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Echo the parsed and pretty printed JSON response to \"/data\". \
            Currently, no processing is done.  This will change in the \
            future." ] @ Common.man_footer

    let term =
      let open Term in
      const (fun common -> WT.data common |> print_json)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "data" ~man) term

  end


module Settings : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Echo the parsed and pretty printed JSON response to \"/settings\". \
            Currently, no processing is done.  This will change in the \
            future." ] @ Common.man_footer

    let term =
      let open Term in
      const (fun common -> WT.settings common |> print_json)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "settings" ~man) term

  end


module Battery : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Print the current changing status." ] @ Common.man_footer

    let term =
      let open Term in
      const (fun common -> WT.format_battery common |> print_endline)
      $ Common.term

    let cmd =
      Cmd.v (Cmd.info "battery" ~man) term

  end


module Main : Unit_Cmd =
  struct

    let man = [
        `S Manpage.s_description;
        `P "Control a WLANThermo Mini V3 on the command line \
            using the HTTP API.";
        `S Manpage.s_examples;
        `Pre "bbqcli alarm -c 9 -t 80-110 -p on";
        `P "Sets the temperature range on channel 9 to [80,110] \
            and switches on the push alert.";
        `Pre "bbqcli temperature -a";
        `P "List the temperatures and limits for all channels, \
            including the limits of disconnected channels."] @ Common.man_footer

    let cmd =
      Cmd.group
        (Cmd.info "bbqcli" ~man)
        [ Temperature.cmd;
          Alarm.cmd;
          Pitmaster.cmd;
          Battery.cmd;
          Data.cmd;
          Settings.cmd;
          Info.cmd ]

  end

let () =
  exit (Cmd.eval Main.cmd)
