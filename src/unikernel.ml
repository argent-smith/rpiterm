module Operations (Time : Mirage_time_lwt.S) (CON : Conduit_mirage.S) = struct
  let log_src = Logs.Src.create "operations" ~doc:"Toplevel operations"
  module Log = Logger.Instance ((val Logs.src_log log_src : Logs.LOG))

  let report_bootup () = Log.info (fun f -> f "Booting up")

  let get_http_port = Key_gen.listen_prometheus
  let get_thermometer_file = Key_gen.thermometer_file

  let start _ conduit =
    let module S = Prometheus_responder.Server(CON) in
    let module L = Thermometry.Loop(Time) in
    [
      report_bootup () >> L.run @@ get_thermometer_file ();
      S.serve_with conduit @@ get_http_port ()
    ] |> Lwt.join
end
