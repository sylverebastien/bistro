(* Internal ppx support is taken from lwt *)

(* OASIS_START *)
(* OASIS_STOP *)

open Ocamlbuild_plugin

let () =
  dispatch
    (fun hook ->
       dispatch_default hook;
       match hook with
         | After_rules ->
             let env = BaseEnvLight.load ~allow_empty:true ~filename:MyOCamlbuildBase.env_filename () in

             (* Determine extension of CompiledObject: best *)
             let native_suffix =
               if BaseEnvLight.var_get "is_native" env = "true"
               then "native" else "byte"
             in

             flag
               ["ocaml"; "compile"; "ppx_bistro"] & S [A "-ppx"; A ("ppx/ppx_bistro." ^ native_suffix)] ;
             flag
               ["ocaml"; "ocamldep"; "ppx_bistro"] & S [A "-ppx"; A ("ppx/ppx_bistro." ^ native_suffix)] ;
             dep ["ocaml"; "ocamldep"; "ppx_bistro"] ["ppx/ppx_bistro." ^ native_suffix]


         | _ ->
           ())
