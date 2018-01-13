open Cmdliner

let info =
  let doc = "A simple Raspberry Pi system thermometer reporter for Prometheus. \
             If run with the option --listen-prometheus=9090, \
             this program serves metrics at http://localhost:9090/metrics" in
  Term.info "rpiterm" ~doc

let thermometer_file =
  let doc = "Optional file containing the system thermometer data."
  and default = "/sys/class/thermal/thermal_zone0/temp"
  and env = Arg.env_var "THERMOMETER_FILE" in
  Arg.(value & opt string default & info ["f"; "thermometer-file"] ~env ~doc)

let operation = Term.(const Operations.main $ thermometer_file $ Prometheus_unix.opts $ Logger.opts ())

let () =
  match Term.eval (operation, info) with
  | `Error _ -> exit 1
  | _ -> exit 0
