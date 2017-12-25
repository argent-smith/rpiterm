module Instance (Src_log : Logs.LOG) = struct
  let info msgf = Lwt.return @@ Src_log.info msgf
  and err msgf = Lwt.return @@ Src_log.err msgf
end
