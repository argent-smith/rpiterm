open Prometheus

let namespace = "node"
and subsystem = "hwmon"

let chip_temperature =
  let help = "Hardware monitor for temperature (input)"
  and label_name = "sensor" in
  Gauge.v_label ~help ~label_name ~namespace ~subsystem "temp_celsius"
