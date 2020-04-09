open Lwt
open Lwt.Infix

let tested_exn = Alcotest.testable Fmt.exn (=)

let check_promise_value checker promise switch () =
  let open Lwt_switch in
  with_switch(
      fun switch ->
      add_hook (Some switch)
               (fun () ->
                 promise >|= checker
                 |> ignore_result
                 |> return)
      |> return
    )

let check_promise_exception checker promise _switch () =
  (try%lwt promise >|= fun _ -> `Ok
    with exn -> Lwt.return @@ `Error exn)
  >|= function
  | `Ok -> Alcotest.fail "No exception was thrown"
  | `Error e -> checker e

let collect_result = function
  | Ok value -> value
  | Error exn -> raise exn

let check_promise_result_value checker promise =
  let promise' = promise >|= collect_result in
  check_promise_value checker promise'

let check_promise_result_failure checker promise =
  let promise' = promise >|= collect_result in
  check_promise_exception checker promise'

let lwt_test_case ~description ~checker ~promise ~strategy =
  Alcotest_lwt.test_case description `Quick @@ strategy checker promise
