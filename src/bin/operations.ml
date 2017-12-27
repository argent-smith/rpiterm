open Lwt

module Log = (val Logger.create "operations" : Logger.LOG)

let setup_signal_handling () =
  let _ = Lwt_unix.on_signal Sys.sigint @@
            fun _ ->
            Log.info "Caught user interruption; exiting" |> ignore_result;
            exit 0
  in ()

let report_bootup () =
  Log.info "Booting up"

let main thermometer_file prometheus_config =
  Logger.setup ();
  setup_signal_handling ();
  let threads = report_bootup ()
                :: Thermometry.run thermometer_file
                :: Prometheus_unix.serve prometheus_config in
  Lwt_main.run @@ join threads
