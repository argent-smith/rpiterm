open Lwt
open Lwt.Infix

module Loop (Time : Mirage_time_lwt.S) = struct
  let get_thermometer_value thermometer_file =
    let module T = Thermometer.Device(Thermometer.Mirage) in
    let%lwt thermometer_value = T.read_temperature ~thermometer_file () in
    Log.info (fun f -> f "Got thermometer value as %.3f" thermometer_value)
    >> return thermometer_value

  let rec run thermometer_file =
    Time.sleep_ns @@ Duration.of_sec 5
    >> get_thermometer_value thermometer_file >|= Prometheus.Gauge.set @@ Metrics.chip_temperature "soc_chip_temp"
    >> run thermometer_file
end
