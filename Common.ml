(* Common.ml -- options for WLANThermo API *)

let host_default = "wlanthermo"

open Cmdliner

let man_footer =
  [ `S Manpage.s_files;
    `P "None, so far.";
    `S Manpage.s_authors;
    `P "Thorsten Ohl <ohl@physik.uni-wuerzburg.de>.";
    `S Manpage.s_bugs;
    `P "Report bugs to <ohl@physik.uni-wuerzburg.de>." ]

let docs = Manpage.s_common_options

let ssl_arg =
  let doc = "Use SSL to connect to the host. \
             This option should never be necessary or even used, \
             because WLANThermo does not understand SSL." in
  let env = Cmd.Env.info "WLANTHERMO_SSL" in
  let open Arg in
  value
  & opt bool ~vopt:true false
  & info ["s"; "ssl"] ~docv:"true/false" ~doc ~docs ~env

let host_arg =
  let doc = "Connect to the host $(docv)." in
  let env = Cmd.Env.info "WLANTHERMO_HOST" in
  let open Arg in
  value
  & opt string host_default
  & info ["H"; "host"] ~docv:"HOST" ~doc ~docs ~env

let verbose_arg =
  let doc = "Be more verbose." in
  let env = Cmd.Env.info "WLANTHERMO_VERBOSITY" in
  let open Arg in
  value
  & opt int 0
  & info ["v"; "verbosity"; "verbose"] ~docv:"VERBOSITY" ~doc ~docs ~env

let timeout_arg =
  let doc = "Wait only $(docv) for response." in
  let env = Cmd.Env.info "WLANTHERMO_TIMEOUT" in
  let open Arg in
  value
  & opt (some int) None
  & info ["T"; "timeout"] ~docv:"SECONDS" ~doc ~docs ~env

let term =
  let open Term in
  const
    (fun ssl host verbosity timeout ->
      { ThoCurl.ssl; ThoCurl.host; ThoCurl.verbosity; ThoCurl.timeout })
  $ ssl_arg
  $ host_arg
  $ verbose_arg
  $ timeout_arg
