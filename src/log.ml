let operations_src = Logs.Src.create "operations" ~doc:"Toplevel operations"

module App_log = (val Logs.src_log operations_src : Logs.LOG)

let info msgf = Lwt.return @@ App_log.info msgf

let err msgf = Lwt.return @@ App_log.err msgf
