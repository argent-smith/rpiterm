open Lwt

module Interface = struct
  module type S = sig
    val read_temperature : ?thermometer_file:string -> unit -> float Lwt.t
  end
end

module Device (D : Interface.S) : Interface.S = struct
  include D
end

module Mockup : Interface.S = struct
  (* Returns 36.6 *)
  let read_temperature ?(thermometer_file = "/dev/zero") () =
    return 36.6
end

module Mirage : Interface.S = struct
  let log_src = Logs.Src.create "thermometer" ~doc:"Thermometer operations"
  module Log = Logger.Instance ((val Logs.src_log log_src : Logs.LOG))

  (* Returns chipset temperature in Celsius as a float *)
  let read_temperature ?(thermometer_file = "/dev/zero") () =
    let open Lwt_io in
    let read_float channel =
      let%lwt str = read_line channel in
      return @@ (float_of_string str) /. 1000.0
    in
    let open Unix in
    try%lwt
      with_file ~mode:input thermometer_file read_float
    with
    | Unix_error(ENOENT, _, fname) ->
       Log.err (fun f -> f "Could not open file %s" fname) >> return 0.0
end
