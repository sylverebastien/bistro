open Core.Std
open Lwt
open Bistro.Std
open Bistro.EDSL
open Bistro_engine

module Workflow = Bistro.Workflow

type txt

let append (xs : txt workflow list) id =
  let echo_cmd = cmd "echo" [ string id ; string ">>" ; dest ] in
  workflow (match xs with
      | [] -> [ echo_cmd ]
      | _ :: _ -> [
          cmd "wc" ~stdout:dest [ string "-l" ; list ~sep:" " dep xs ] ;
          echo_cmd ;
        ])

let pipeline n =
  let root = append [] "root" in
  let l1 = List.init n ~f:(fun i -> append [ root ] (sprintf "l1_%d" i)) in
  let middle = append l1 "middle" in
  let l2 = List.init n ~f:(fun i -> append [ middle ] (sprintf "l2_%d" i)) in
  let final = append l2 "final" in
  final

let main n () =
  let open Bistro_app in
  let logger = Bistro_console_logger.create () in
  run ~logger (pureW (pipeline n))
  |> ignore

let command =
  Command.basic
    ~summary:"Performance test on large pipelines"
    Command.Spec.(
      empty
      +> flag "-n" (required int) ~doc:"INT size of the pipeline"
    )
    main
