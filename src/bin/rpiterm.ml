let () =
  let open Cmdliner in
  let info =
    let doc = "A simple Raspberry Pi system thermometer reporter for Prometheus. \
               If run with the option --listen-prometheus=9090, \
               this program serves metrics at http://localhost:9090/metrics" in
    Term.info "rpiterm" ~doc
  and spec = Term.(const Operations.main $ Prometheus_unix.opts) in
  match Term.eval (spec, info) with
  | `Error _ -> exit 1
  | _ -> exit 0
