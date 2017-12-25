open Lwt

module Loop (Time : Mirage_time_lwt.S) = struct
  let log_src = Logs.Src.create "thermometry" ~doc:"Thermometry operations"
  module Log = Logger.Instance ((val Logs.src_log log_src : Logs.LOG))

  let get_thermometer_value thermometer_file =
    let open Thermometer in
    let module T = Device (Mirage) in
    let%lwt thermometer_value = T.read_temperature ~thermometer_file () in
    Log.info (fun f -> f "Got thermometer value as %.3f" thermometer_value)
    >> return thermometer_value

  let rec run thermometer_file =
    Time.sleep_ns @@ Duration.of_sec 5
    >> get_thermometer_value thermometer_file >|= Prometheus.Gauge.set @@ Metrics.chip_temperature "soc_chip_temp"
    >> run thermometer_file
end
