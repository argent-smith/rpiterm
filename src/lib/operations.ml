open Lwt

let source = Logs.Src.create "operations" ~doc:"Toplevel operations"
module Log = (val Logger.create ~source : Logger.LOG)

let setup_signal_handling () =
  let _ = Lwt_unix.on_signal Sys.sigint @@
            fun _ ->
            Log.warn (fun f -> f "Caught user interruption; exiting") |> ignore_result;
            exit 0
  in ()

let report_bootup () =
  Log.info (fun f -> f "Booting up")

let main thermometer_file prometheus_config =
  Logger.setup ();
  setup_signal_handling ();
  let threads = (report_bootup () >>= fun () -> Thermometry.run thermometer_file)
                :: Prometheus_unix.serve prometheus_config in
  Lwt_main.run @@ choose threads
