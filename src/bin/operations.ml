open Lwt
open Lwt.Infix

let section = Lwt_log.Section.make "operations"

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
  Lwt_log.info_f ~section "Booting up"

let main thermometer_file prometheus_config =
  setup_logging ();
  setup_signal_handling ();
  let threads = report_bootup ()
                :: Thermometry.run thermometer_file
                :: Prometheus_unix.serve prometheus_config in
  Lwt_main.run @@ join threads
