open Lwt
open Lwt.Infix

module Metrics = struct
  open Prometheus

  let namespace = "node"
  and subsystem = "hwmon"

  let chip_temperature =
    let help = "Hardware monitor for temperature (input)"
    and label_name = "sensor" in
    Gauge.v_label ~help ~label_name ~namespace ~subsystem "temp_celsius"
end

let setup_logging () =
  Lwt_log.(
    let template = "$(date).$(milliseconds) $(name)[$(pid)]: $(level)($(section)) => $(message)" in
    default := broadcast [channel ~template ~close_mode:`Keep ~channel:Lwt_io.stdout ()];
    add_rule "*" Info
  )

let setup_signal_handling () =
  let _ = Lwt_unix.on_signal Sys.sigint @@
            fun _ ->
            Lwt_log.info_f "Caught user interruption; exiting" |> ignore_result;
            exit 0
  in ()

let report_bootup () =
  Lwt_log.info_f "Booting up"

(* TODO: implement the getting protocol *)
let get_thermometer_value () =
  let%lwt thermometer_value = return (36600.0 /. 1000.0) in
  Lwt_log.info_f "Got thermometer value as %.1f" thermometer_value
  >> return thermometer_value

let rec set_thermometer () =
  Lwt_unix.sleep 1.0
  >> get_thermometer_value () >|= Prometheus.Gauge.set @@ Metrics.chip_temperature "soc_chip_temp"
  >> set_thermometer ()

let main prometheus_config =
  setup_logging ();
  setup_signal_handling ();
  let threads = report_bootup () :: set_thermometer () :: Prometheus_unix.serve prometheus_config in
  Lwt_main.run @@ Lwt.join threads

let () =
  let open Cmdliner in
  let info =
    let doc = "A simple Raspberry Pi system thermometer reporter for Prometheus. \
               If run with the option --listen-prometheus=9090, \
               this program serves metrics at http://localhost:9090/metrics" in
    Term.info "rpiterm" ~doc
  and spec = Term.(const main $ Prometheus_unix.opts) in
  match Term.eval (spec, info) with
  | `Error _ -> exit 1
  | _ -> exit 0
