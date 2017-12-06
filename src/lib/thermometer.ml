open Lwt
open Lwt.Infix

module Interface = struct
  module type S = sig
    val read_temperature : unit -> float Lwt.t
  end
end

module Device (D : Interface.S) : Interface.S = struct
  include D
end

module Mockup : Interface.S = struct
  (* Returns 36.6 *)
  let read_temperature () = return @@ 36600.0 /. 1000.0
end

module Linux : Interface.S = struct
  let temp_file = "/sys/class/thermal/thermal_zone0/temp"

  (* Returns chipset temperature in Celsius as a float *)
  let read_temperature () =
    let open Lwt_io in
    let read_float channel =
      let%lwt str = read_line channel in
      return @@ (float_of_string str) /. 1000.0
    in
    with_file ~mode:input temp_file read_float
end
