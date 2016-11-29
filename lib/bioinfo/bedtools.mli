open Bistro.Std
open Defs

val env : Bistro.docker_image

type 'a input

val bed : #bed3 input
val gff : gff input

module Cmd : sig
  val slop :
    ?strand:bool ->
    ?header:bool ->
    mode:[
      | `both of int
      | `left of int
      | `right of int
      | `both_pct of float
      | `left_pct of float
      | `right_pct of float
    ] ->
    'a input ->
    'a workflow ->
    Ucsc_gb.chrom_sizes workflow ->
    Bistro.command
end


val slop :
  ?strand:bool ->
  ?header:bool ->
  mode:[
    | `both of int
    | `left of int
    | `right of int
    | `both_pct of float
    | `left_pct of float
    | `right_pct of float
  ] ->
  'a input ->
  'a workflow ->
  Ucsc_gb.chrom_sizes workflow ->
  'a workflow