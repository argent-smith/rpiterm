open Lwt

type config = {
    log_times: bool;
    log_process: bool
  }

type 'a log = ('a, unit) Logs.msgf -> unit Lwt.t

module type LOG = sig
  val info : 'a log
  val warn : 'a log
  val err : 'a log
end

let logs_data_of_level l =
  let open Logs in
  match l with
  | App -> ("APP", `Cyan)
  | Error -> ("ERR", `Red)
  | Warning -> ("WRN", `Yellow)
  | Info -> ("INF", `Blue)
  | Debug -> ("DBG", `Green)

let pp_header ~pp_h ppf (cfg, l, h) =
  let abbr, style = logs_data_of_level l in
  match l with
  | Logs.App ->
    begin match h with
    | None -> ()
    | Some h -> Fmt.pf ppf "[%a] " Fmt.(styled style string) h
    end
  | _ ->
     pp_h cfg ppf style (match h with None -> abbr | Some h -> h)

let pp_time config =
  let tz_offset_s = match Ptime_clock.current_tz_offset_s () with None -> 0 | Some s -> s in
  let formatter ppf time =
    Fmt.pf ppf "@[%a@ @]" (Ptime.pp_human ~tz_offset_s ()) time
  in
  match config.log_times with
  | true -> formatter
  | false -> Fmt.nop

let pp_process config =
  let pid = Unix.getpid ()
  and exe = match Array.length Sys.argv with
    | 0 -> Filename.basename Sys.executable_name
    | n -> Filename.basename Sys.argv.(0)
  in
  let formatter ppf () =
    Fmt.pf ppf "@[[%i]@ %s:@ @]" pid exe
  in
  match config.log_process with
  | true -> formatter
  | false -> Fmt.nop

let pp_header =
  let pp_h config ppf style h =
    let pp_time = pp_time config
    and pp_process = pp_process config
    and time = Ptime_clock.now () in
    Fmt.pf ppf "%a%a[%a]" pp_time time pp_process () Fmt.(styled style string) h
  in
  pp_header ~pp_h

let reporter config =
  let buf_fmt ~like =
    let b = Buffer.create 512 in
    Fmt.with_buffer ~like b,
    fun () -> let m = Buffer.contents b in Buffer.reset b; m
  in
  let app, app_flush = buf_fmt ~like:Fmt.stdout
  and dst, dst_flush = buf_fmt ~like:Fmt.stderr in
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
    let formatter ?header ?tags fmt =
      let k _ = over (); k () in
      let ppf = if level = App then app else dst in
      Fmt.kpf k ppf ("%a @[%s@]: @[" ^^ fmt ^^ "@]@.") pp_header (config, level, header) (Logs.Src.name src)
    in
    msgf formatter
  in
  { Logs.report = report }

let setup config =
  Fmt_tty.setup_std_outputs ();
  Logs.set_level @@ Some Logs.Info;
  Logs.set_reporter @@ reporter config

let create ~source =
  let module Src_log = (val Logs.src_log source : Logs.LOG) in
  let module Log = struct
      let info msgf = Src_log.info msgf |> return
      and warn msgf = Src_log.warn msgf |> return
      and err msgf = Src_log.err msgf |> return
    end
  in
  (module Log : LOG)

open Cmdliner

let docs = "LOGGING OPTIONS"

let log_times =
  let doc = Arg.(info ~docs
                      ~docv:"BOOL"
                      ~doc:"Whether to timestamp log messages."
                      ~env:(env_var "LOG_TIMES")
                      ["log-times"; "T"]) in
  Arg.(value @@ flag doc)

let log_process =
  let doc = Arg.(info ~docs
                      ~docv:"BOOL"
                      ~env:(env_var "LOG_PROCESS")
                      ~doc:"Whether to add process info (name & pid) to log messages."
                      ["log-process"; "P"]) in
  Arg.(value @@ flag doc)

let opts () =
  let combine log_times log_process =
    { log_times; log_process }
  in
  Term.(const combine $ log_times $ log_process)
