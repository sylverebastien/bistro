open Core.Std
open Bistro.Std
open Bistro.EDSL

let echo s =
  workflow [
    cmd "echo" [ string s ]
  ]

let double fn =
  let s = In_channel.read_all fn in
  s ^ s

let double w =
  let open E in
  primitive "double" double $ dep w
  |> value

let main () =
  let open Bistro_app in
  let w = double (echo "42!") in
  let app = pure ignore $ pureW w in
  run app

let command =
  Command.basic
    ~summary:"Tests function call tasks"
    Command.Spec.empty
    main
