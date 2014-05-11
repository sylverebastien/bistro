type backend =
  np:int -> mem:int ->
  stdout:string -> stderr:string ->
  Bistro_logger.t ->
  string -> unit Lwt.t

val local_worker : np:int -> mem:int -> backend

val exec : Bistro_db.t -> Bistro_logger.t -> backend -> _ Bistro_workflow.t -> unit Lwt.t
val dryrun : Bistro_db.t -> _ Bistro_workflow.t -> unit Lwt.t

val build_repo :
  base:string ->
  ?wipeout:bool->
  Bistro_db.t -> Bistro_logger.t -> backend -> Bistro_repo.t -> unit Lwt.t