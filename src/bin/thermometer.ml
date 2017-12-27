open Lwt
open Lwt.Infix

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
    return @@ 36600.0 /. 1000.0
end

module Linux : Interface.S = struct
  module Log = (val Logger.create "linux system thermometer" : Logger.LOG)

  (* Returns chipset temperature in Celsius as a float *)
  let read_temperature ?(thermometer_file = "/dev/zero") () =
    let open Lwt_io in
    let read_float channel =
      let%lwt str = read_line channel in
      return @@ (float_of_string str) /. 1000.0
    in
    try%lwt
      with_file ~mode:input thermometer_file read_float
    with
    | Unix.(Unix_error(ENOENT, _, fname)) as e ->
       Log.fatal "Could not open file %s" fname
       >>= fun () -> fail e
end
