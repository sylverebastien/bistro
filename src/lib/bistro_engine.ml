open Core.Std

type backend =
  np:int -> mem:int -> timeout:Bistro_workflow.duration ->
  interpreter:Bistro_workflow.interpreter ->
  stdout:string -> stderr:string ->
  string -> [`Ok | `Error]

let remove_if_exists fn =
  if Sys.file_exists fn = `Yes
  then Sys.command_exn ("rm -r " ^ fn) |> ignore

let cmd_of_interpreter script_file = function
  | `bash -> Shell.cmd "bash" [ script_file ]
  | `ocaml -> Shell.cmd "ocaml" [ script_file ]
  | `perl -> Shell.cmd "perl" [ script_file ]
  | `python -> Shell.cmd "python" [ script_file ]
  | `R -> Shell.cmd "R" [ "CMD" ; script_file ]
  | `sh -> Shell.cmd "sh" [ script_file ]

let string_of_process_status ps =
  Unix.Exit_or_signal.(
    of_unix ps
    |> to_string_hum
  )

let local_worker (log : Bistro_log.t) ~np ~mem ~timeout ~interpreter ~stdout ~stderr script =
  let ext = Bistro_workflow.extension_of_interpreter interpreter in
  let script_file = Filename.temp_file "bistro" ("." ^ ext) in
  Bistro_log.debug log "Exec script %s:\n%s\n" script_file script ;
  Out_channel.write_all script_file ~data:script ;
  try
    Shell.call
      ~stdout:(Shell.to_file stdout)
      ~stderr:(Shell.to_file stderr)
      [ cmd_of_interpreter script_file interpreter ] ;
    Unix.unlink script_file ;
    `Ok
  with Shell.Subprocess_error l -> (
      List.iter l ~f:(fun (_, status) ->
          Bistro_log.error log
            "Script %s failed!\nError status: %s\nstdout: %s\nstderr: %s\n"
            script_file (string_of_process_status status) stdout stderr
        ) ;
      `Error
    )

let run db log backend w =
  let foreach = Bistro_workflow.(function
    | Input p ->
      if Sys.file_exists p <> `Yes
      then failwithf "File %s is declared as an input of a workflow but does not exist." p ()

    | Select (_, p) as x ->
      if Sys.file_exists (Bistro_db.path db x) <> `Yes
      then failwithf "No file or directory named %s in directory workflow." p ()
    | Rule ({ np ; mem ; timeout ; interpreter } as r) as x ->
      if not (Sys.file_exists_exn (Bistro_db.path db x)) then (
        let stdout = Bistro_db.stdout_path db x in
        let stderr = Bistro_db.stderr_path db x in
        let build_path = Bistro_db.build_path db x in
        let tmp_path = Bistro_db.tmp_path db x in
        let script = script_to_string ~dest:build_path ~tmp:tmp_path (Bistro_db.path db) r.script in
        remove_if_exists tmp_path ;
        Sys.command_exn ("mkdir -p " ^ tmp_path) ;
        Bistro_log.started_build log x ;
        match backend ~np ~mem ~timeout ~interpreter ~stdout ~stderr script with
        | `Ok ->
          Bistro_log.finished_build log x ;
          Unix.rename ~src:build_path ~dst:(Bistro_db.path db x) ;
          remove_if_exists tmp_path
        | `Error ->
          Bistro_log.failed_build log x ;
          failwithf "Build of workflow %s failed!" (Bistro_workflow.digest x) ()
      )
    )
  in
  Bistro_workflow.depth_first_traversal
    ~init:()
    ~f:(fun w () -> foreach w)
    w
