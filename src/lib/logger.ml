open Lwt

let reporter () =
  let buf_fmt ~like =
    let b = Buffer.create 512 in
    Fmt.with_buffer ~like b,
    fun () -> let m = Buffer.contents b in Buffer.reset b; m
  in
  let app, app_flush = buf_fmt ~like:Fmt.stdout
  and dst, dst_flush = buf_fmt ~like:Fmt.stderr in
  let reporter = Logs_fmt.reporter ~app ~dst () in
  let report src level ~over k msgf =
    let k () =
      let open Lwt_io in
      let write () = match level with
        | Logs.App -> write stdout @@ app_flush ()
        | _ -> write stderr @@ dst_flush ()
      in
      let unblock () = over (); return_unit in
      finalize write unblock |> ignore_result;
      k ()
    in
    reporter.Logs.report src level ~over:(fun () -> ()) k msgf
  in
  { Logs.report = report }

let setup () =
  Fmt_tty.setup_std_outputs ();
  Logs.set_level @@ Some Logs.Info;
  Logs.set_reporter @@ reporter ()

module type LOG = sig
  val info : ('a, unit) Logs.msgf -> unit Lwt.t
  val warn : ('a, unit) Logs.msgf -> unit Lwt.t
  val err : ('a, unit) Logs.msgf -> unit Lwt.t
end

let create ~source =
  let module Src_log = (val Logs.src_log source : Logs.LOG) in
  let module Log = struct
      let info msgf = Src_log.info msgf |> return
      and warn msgf = Src_log.warn msgf |> return
      and err msgf = Src_log.err msgf |> return
    end
  in
  (module Log : LOG)
