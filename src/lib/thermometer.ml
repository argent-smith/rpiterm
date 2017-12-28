open Lwt
open Lwt.Infix

module type THERMOMETER = sig
  val read_temperature : ?thermometer_file: string option -> unit -> float result Lwt.t
end

exception No_thermometer_file

module Mockup : THERMOMETER = struct
  (* Returns 36.6 *)
  let read_temperature ?(thermometer_file = None) () =
    return @@ Ok (36600.0 /. 1000.0)
end

module Linux : THERMOMETER = struct
  (* Returns chipset temperature in Celsius as a float *)
  let read_temperature ?(thermometer_file = None) () =
    match thermometer_file with
    | None -> return @@ Error No_thermometer_file
    | Some filename ->
       let open Lwt_io in
       let read_float channel =
         let%lwt str = read_line channel in
         return @@ Ok ((float_of_string str) /. 1000.0)
       in
       try%lwt
             with_file ~mode:input filename read_float
       with
       | exn -> return @@ Error exn
end
