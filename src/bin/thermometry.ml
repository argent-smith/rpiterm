open Lwt
open Lwt.Infix

module Log = (val Logger.create "thermometry" : Logger.LOG)

let get_thermometer_value thermometer_file =
  let module T = Thermometer.Device(Thermometer.Linux) in
  let%lwt thermometer_value = T.read_temperature ~thermometer_file () in
  Log.info "Got thermometer value as %.3f" thermometer_value
  >>= fun () -> return thermometer_value

let rec run thermometer_file =
  Lwt_unix.sleep 5.0
  >>= (fun () -> get_thermometer_value thermometer_file)
  >|= Prometheus.Gauge.set @@ Metrics.chip_temperature "soc_chip_temp"
  >>= fun () -> run thermometer_file
