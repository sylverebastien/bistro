type t =
  | Input of string * path
  | Select of string * [`Input of path | `Step of string] * path
  | Step of step

and step = {
  id       : id ;
  descr    : string ;
  deps     : dep list ;
  action   : action ;
  np       : int ; (** Required number of processors *)
  mem      : int ; (** Required memory in MB *)
  timeout  : int option ; (** Maximum allowed running time in hours *)
  version  : int option ; (** Version number of the wrapper *)
  precious : bool ;
}

and dep = [
    `Task of id
  | `Select of id * path
  | `Input of path
]
and id = string

and action =
  | Command of command
  | Compute of some_expr

and some_expr =
  | Value     : _ expr    -> some_expr
  | File      : unit expr -> some_expr
  | Directory : unit expr -> some_expr

and _ expr =
  | E_primitive : { id : string ; value : 'a } -> 'a expr
  | E_app : ('a -> 'b) expr * 'a expr -> 'b expr
  | E_dest : string expr
  | E_tmp : string expr
  | E_np : int expr
  | E_mem : int expr
  | E_dep : dep -> string expr

and command =
  | Docker of Bistro.docker_image * command
  | Simple_command of token list
  | And_list of command list
  | Or_list of command list
  | Pipe_list of command list

and token =
  | S of string
  | D of dep
  | F of token list
  | DEST
  | TMP
  | NP
  | MEM

and path = Bistro.Path.t

type result =
  | Input_check of { path : string ; pass : bool }
  | Select_check of { dir_path : string ; sel : string list ; pass : bool }
  | Step_result of {
      outcome : [`Succeeded | `Missing_output | `Failed] ;
      step : step ;
      exit_code : int ;
      action : [`Sh of string | `Eval] ;
      dumps : (string * string) list ;
      cache : string option ;
      stdout : string ;
      stderr : string ;
    }

type config = private {
  db : Db.t ;
  use_docker : bool ;
  keep_all : bool ;
}

val config :
  db_path:string ->
  use_docker:bool ->
  keep_all:bool ->
  config

val of_workflow : Bistro.u -> t
val id : t -> string
val requirement : t -> Allocator.request
val perform : Allocator.resource -> config -> t -> result Lwt.t
val failure : result -> bool
val is_done : t -> config -> bool Lwt.t
val post_revdeps_hook :
  t ->
  config ->
  all_revdeps_succeeded:bool ->
  unit Lwt.t
val clean : t -> config -> unit Lwt.t

(* LOW-LEVEL API *)
val render_step_command : np:int -> mem:int -> config -> step -> command -> string
val render_step_dumps : np:int -> mem:int -> config -> step -> (string * string) list
