open Lwt
open Lwt.Infix

module Log = (val Logger.create "thermometry" : Logger.LOG)

let get_thermometer_value thermometer_file =
  let module T = Thermometer.Linux in
  let%lwt thermometer_value = T.read_temperature ~thermometer_file () in
  match thermometer_value with
  | Ok number ->
     Log.info "Got thermometer value as %.3f" number
     >>= fun () -> return number
  | Error exn ->
     Log.fatal ~exn "Failed getting thermometer value"
     >>= fun () -> fail exn

let rec run thermometer_file =
  Lwt_unix.sleep 5.0
  >>= (fun () -> get_thermometer_value @@ Some thermometer_file)
  >|= Prometheus.Gauge.set @@ Metrics.chip_temperature "soc_chip_temp"
  >>= fun () -> run thermometer_file
