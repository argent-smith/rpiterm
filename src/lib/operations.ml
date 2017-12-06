open Lwt
open Lwt.Infix

let setup_logging () =
  let open Lwt_log in
  let template = "$(date).$(milliseconds) $(name)[$(pid)]: $(level)($(section)) => $(message)" in
  default := broadcast [channel ~template ~close_mode:`Keep ~channel:Lwt_io.stdout ()];
  add_rule "*" Info

let setup_signal_handling () =
  let _ = Lwt_unix.on_signal Sys.sigint @@
            fun _ ->
            Lwt_log.info_f "Caught user interruption; exiting" |> ignore_result;
            exit 0
  in ()

let report_bootup () =
  Lwt_log.info_f "Booting up"

let get_thermometer_value () =
  let module T = Thermometer.Device(Thermometer.Linux) in
  let%lwt thermometer_value = T.read_temperature () in
  Lwt_log.info_f "Got thermometer value as %.3f" thermometer_value
  >> return thermometer_value

let rec set_thermometer () =
  Lwt_unix.sleep 5.0
  >> get_thermometer_value () >|= Prometheus.Gauge.set @@ Metrics.chip_temperature "soc_chip_temp"
  >> set_thermometer ()

let main prometheus_config =
  setup_logging ();
  setup_signal_handling ();
  let threads = report_bootup () :: set_thermometer () :: Prometheus_unix.serve prometheus_config in
  Lwt_main.run @@ Lwt.join threads
