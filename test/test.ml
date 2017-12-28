open Lwt
open Lwt.Infix

(* Tests per se *)
module Thermometer_tests = struct
  let collect_float_result = function
    | Ok number -> number
    | Error exn -> raise exn

  module Mockup_thermometer_tests = struct
    let value_reading () =
      let test =
        Thermometer.Mockup.read_temperature ()
        >|= collect_float_result
        >|= Alcotest.(check (float 0.0)) "'reads' body temperature" 36.6
      in
      Lwt_main.run test

    let file_ignoring () =
      let test =
        let thermometer_file = Some "name" in
        Thermometer.Mockup.read_temperature ~thermometer_file ()
        >|= collect_float_result
        >|= Alcotest.(check (float 0.0)) "ignores optional file name" 36.6
      in
      Lwt_main.run test

    let noop_file_ignoring () =
      let test =
        let thermometer_file = None in
        Thermometer.Mockup.read_temperature ~thermometer_file ()
        >|= collect_float_result
        >|= Alcotest.(check (float 0.0)) "ignores nonexistent file name" 36.6
      in
      Lwt_main.run test
  end

  module Linux_thermometer_tests = struct
    let value_reading () =
      let test =
        let thermometer_file = Some "tempfile" in
        Thermometer.Linux.read_temperature ~thermometer_file ()
        >|= collect_float_result
        >|= Alcotest.(check (float 0.0)) "reads body temperature from the file" 36.6
      in
      Lwt_main.run test

    let file_opening_failure () =
      let filename = "non_existent_file" in
      let test = fun () ->
        let thermometer_file = Some filename in
        let computation = fun () ->
          let _ =
            Lwt_main.run (Thermometer.Linux.read_temperature ~thermometer_file ()
                          >|= collect_float_result) in
          ()
        in
        let exn = Unix.Unix_error(Unix.ENOENT, "open", filename) in
        Alcotest.check_raises "reports error" exn computation
      in
      test ()

    let noop_file_failure () =
      let test = fun () ->
        let computation = fun () ->
          let thermometer_file = None in
          let _ =
            Lwt_main.run (Thermometer.Linux.read_temperature ~thermometer_file ()
                          >|= collect_float_result) in
          ()
        in
        Alcotest.check_raises "reports error" Thermometer.No_thermometer_file computation
      in
      test ()

    let nonspecified_file_failure () =
      let test = fun () ->
        let computation = fun () ->
          let _ =
            Lwt_main.run (Thermometer.Linux.read_temperature ()
                          >|= collect_float_result) in
          ()
        in
        Alcotest.check_raises "reports error" Thermometer.No_thermometer_file computation
      in
      test ()
  end
end

module Thermometry_tests = struct
  let value_getting () =
    let test =
      let filename = "tempfile" in
      Thermometry.get_thermometer_value @@ Some filename
      >|= Alcotest.(check (float 0.0)) "'reads' body temperature" 36.6
    in
    Lwt_main.run test

  let nofile_failure () =
    let test = fun () ->
      let computation = fun () ->
        let _ =
          Lwt_main.run @@ Thermometry.get_thermometer_value None in ()
      in
      Alcotest.check_raises "reports error" Thermometer.No_thermometer_file computation
      in test ()

  let wrong_file_failure () =
    let filename = "tempfile_wrong" in
    let test = fun () ->
      let computation = fun () ->
        let _ =
          Lwt_main.run @@ Thermometry.get_thermometer_value @@ Some filename in ()
      in
      let exn = Unix.Unix_error(Unix.ENOENT, "open", filename) in
      Alcotest.check_raises "reports error" exn computation
      in test ()
end

let mockup_thermometer_tests = [
    "Value reading", `Slow, Thermometer_tests.Mockup_thermometer_tests.value_reading;
    "File ignoring", `Slow, Thermometer_tests.Mockup_thermometer_tests.file_ignoring;
    "Noop file ignoring", `Slow, Thermometer_tests.Mockup_thermometer_tests.noop_file_ignoring
  ]

let linux_thermometer_tests = [
    "Value reading", `Slow, Thermometer_tests.Linux_thermometer_tests.value_reading;
    "File opening failure", `Slow, Thermometer_tests.Linux_thermometer_tests.file_opening_failure;
    "Noop file failure", `Slow, Thermometer_tests.Linux_thermometer_tests.noop_file_failure;
    "Nonspecified file failure", `Slow, Thermometer_tests.Linux_thermometer_tests.nonspecified_file_failure
  ]

let thermometry_tests = [
    "Value getting", `Slow, Thermometry_tests.value_getting;
    "Nofile failure", `Slow, Thermometry_tests.nofile_failure;
    "Wrong file failure", `Slow, Thermometry_tests.wrong_file_failure
  ]

(* Run it *)
let () =
  Alcotest.run "Thermometers" [
    "Mockup thermometer", mockup_thermometer_tests;
    "Linux thermometer", linux_thermometer_tests;
    "Thermometry dispatcher", thermometry_tests
  ]
