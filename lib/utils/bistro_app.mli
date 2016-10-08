open Bistro.Std

type 'a t

val pure : 'a -> 'a t

val pureW : _ workflow -> (string -> 'a) -> 'a t

val app : ('a -> 'b) t -> 'a t -> 'b t

val ( $ ) : ('a -> 'b) t -> 'a t -> 'b t

val list : 'a t list -> 'a list t

val run :
  ?use_docker:bool ->
  ?np:int ->
  ?mem:int ->
  ?verbose:bool ->
  'a t -> 'a

type repo_item

val ( %> ) : string list -> _ workflow -> repo_item

val of_repo : outdir:string -> repo_item list -> unit t
