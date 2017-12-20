open Mirage

let packages = [
    package "duration";
    package "prometheus";
    package "prometheus-app";
    package "cohttp-mirage"
  ]

let thermometer_file =
  let doc = Key.Arg.info
              ~doc:"Optional file containing the system thermometer data."
              ~env:"THERMOMETER_FILE"
              ~docv:"STRING"
              ["thermometer-file"]
  in
  Key.(create "thermometer-file" Arg.(opt string "/sys/class/thermal/thermal_zone0/temp" doc))

let listen_prometheus =
  let doc = Key.Arg.info
              ~doc:"Port on which to provide Prometheus metrics over HTTP."
              ~env:"LISTEN_PROMETHEUS"
              ~docv:"PORT"
              ["listen-prometheus"]
  in
  Key.(create "listen-prometheus" Arg.(opt int 9100 doc))

let keys = Key.([
                   abstract thermometer_file;
                   abstract listen_prometheus
           ])

let () =
  let main = foreign
               ~keys
               ~packages
               "Unikernel.Operations" (time @-> conduit @-> job)
  in
  register "rpiterm" [main $ default_time $ conduit_direct @@ generic_stackv4 default_network]
