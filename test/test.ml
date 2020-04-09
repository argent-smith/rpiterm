open Test_utils

module Thermometer_tests = struct
  module Mockup_thermometer_tests = struct
    let value_reading =
      let description = "Value reading"
      and checker = Alcotest.(check (float 0.0)) "read_temperature \"reads\" body temperature" 36.6
      and promise = Thermometer.Mockup.read_temperature ()
      and strategy = check_promise_result_value in
      lwt_test_case ~description ~checker ~promise ~strategy

    let file_ignoring =
      let description = "File ignoring" in
      let thermometer_file = Some "name" in
      let checker = Alcotest.(check (float 0.0)) "read_temperature ignores optional file name" 36.6
      and promise = Thermometer.Mockup.read_temperature ~thermometer_file ()
      and strategy = check_promise_result_value in
      lwt_test_case ~description ~checker ~promise ~strategy

    let noop_file_ignoring =
      let description = "Noop file ignoring" in
      let thermometer_file = None in
      let checker = Alcotest.(check (float 0.0)) "read_temperature ignores nonexistent file name" 36.6
      and promise = Thermometer.Mockup.read_temperature ~thermometer_file ()
      and strategy = check_promise_result_value in
      lwt_test_case ~description ~checker ~promise ~strategy
  end

  module Linux_thermometer_tests = struct
    let value_reading =
      let description = "Value reading" in
      let thermometer_file = Some "tempfile" in
      let checker = Alcotest.(check (float 0.0)) "read_temperature reads temperature from the file" 36.6
      and promise = Thermometer.Mockup.read_temperature ~thermometer_file ()
      and strategy = check_promise_result_value in
      lwt_test_case ~description ~checker ~promise ~strategy

    let file_opening_failure =
      let description = "File opening failure" in
      let filename = "non_existent_file" in
      let thermometer_file = Some filename in
      let exn = Unix.Unix_error(Unix.ENOENT, "open", filename) in
      let checker = Alcotest.(check tested_exn) "reports error" exn
      and promise = Thermometer.Linux.read_temperature ~thermometer_file ()
      and strategy = check_promise_result_failure in
      lwt_test_case ~description ~checker ~promise ~strategy

    let noop_file_failure =
      let description = "Noop file failure" in
      let thermometer_file = None in
      let checker = Alcotest.(check tested_exn) "reports error" Thermometer.No_thermometer_file
      and promise = Thermometer.Linux.read_temperature ~thermometer_file ()
      and strategy = check_promise_result_failure in
      lwt_test_case ~description ~checker ~promise ~strategy

    let nonspecified_file_failure =
      let description = "Nonspecified file failure" in
      let checker = Alcotest.(check tested_exn) "reports error" Thermometer.No_thermometer_file
      and promise = Thermometer.Linux.read_temperature ()
      and strategy = check_promise_result_failure in
      lwt_test_case ~description ~checker ~promise ~strategy
  end
end

module Thermometry_tests = struct
  let value_getting =
    let description = "Value getting" in
    let thermometer_file = Some "tempfile" in
    let checker = Alcotest.(check (float 0.0)) "get_thermometer_value reads temperature from the file" 36.6
    and promise = Thermometry.get_thermometer_value thermometer_file
    and strategy = check_promise_value in
    lwt_test_case ~description ~checker ~promise ~strategy

  let nofile_failure =
    let description = "Nofile failure" in
    let thermometer_file = None
    and exn = Thermometer.No_thermometer_file in
    let checker = Alcotest.(check tested_exn) "get_thermometer_value reports error if noop file specified" exn
    and promise = Thermometry.get_thermometer_value thermometer_file
    and strategy = check_promise_exception in
    lwt_test_case ~description ~checker ~promise ~strategy

  let wrong_file_failure =
    let description = "Wrong file failure" in
    let filename = "tempfile_wrong" in
    let thermometer_file = Some filename
    and exn = Unix.Unix_error(Unix.ENOENT, "open", filename) in
    let checker = Alcotest.(check tested_exn) "get_thermometer_value reports error if wrong file specified" exn
    and promise = Thermometry.get_thermometer_value thermometer_file
    and strategy = check_promise_exception in
    lwt_test_case ~description ~checker ~promise ~strategy
end

let mockup_thermometer_tests =
  Thermometer_tests.Mockup_thermometer_tests.
  [
    value_reading;
    file_ignoring;
    noop_file_ignoring
  ]

let linux_thermometer_tests =
  Thermometer_tests.Linux_thermometer_tests.
  [
    value_reading;
    file_opening_failure;
    noop_file_failure;
    nonspecified_file_failure
  ]

let thermometry_tests =
  Thermometry_tests.
  [
    value_getting;
    nofile_failure;
    wrong_file_failure
  ]

let () =
  Lwt_main.run @@
    Alcotest_lwt.run "Thermometers" [
        "Mockup thermometer", mockup_thermometer_tests;
        "Linux thermometer", linux_thermometer_tests;
        "Thermometry dispatcher", thermometry_tests
      ]
