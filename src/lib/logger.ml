open Lwt

let setup () =
  let open Lwt_log in
  let template = "$(date).$(milliseconds) [$(pid)] $(name) [$(level)] $(section): $(message)" in
  default := broadcast [channel ~template ~close_mode:`Keep ~channel:Lwt_io.stdout ()];
  add_rule "*" Info

module type LOG = sig
  val info :
    ?exn:exn ->
    ?location:string * int * int ->
    ?logger:Lwt_log.logger -> ('a, unit, string, unit Lwt.t) format4 -> 'a

  val fatal :
    ?exn:exn ->
    ?location:string * int * int ->
    ?logger:Lwt_log.logger -> ('a, unit, string, unit Lwt.t) format4 -> 'a
end

let create section_id =
  let section = Lwt_log.Section.make section_id in
  let module Log = struct
      let info = Lwt_log.info_f ~section
      let fatal = Lwt_log.fatal_f ~section
    end
  in
  (module Log : LOG)
