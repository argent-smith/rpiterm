(** Logging facility *)

(** Logger configuration record *)
type config = {
    log_times: bool; (** Whether to add timestamps to the logs *)
    log_process: bool (** Whether to add process info to the logs *)
  }

(** Basic logging function type *)
type 'a log = ('a, unit) Logs.msgf -> unit Lwt.t

(** Generated logger module type *)
module type LOG = sig
  val info : 'a log
  val warn : 'a log
  val err : 'a log
end

(** Sets up application-wide logging *)
val setup : config -> unit

(** Creates logger module for specified source *)
val create : source:Logs.src -> (module LOG)

(** Cli options function to be used in toplevel Cmdliner setup *)
val opts : unit -> config Cmdliner.Term.t
