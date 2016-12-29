#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let metas = [
  Pkg.meta_file ~install:false "pkg/META";
  Pkg.meta_file ~install:false "pkg/META.lwt";
]

let opams =
  let opam no_lint name =
    Pkg.opam_file ~lint_deps_excluding:(Some no_lint) ~install:false name
  in
  [
  opam ["lwt"; "mirage-protocols"; "ipaddr"; "cstruct"; "result"] "opam";
  opam ["fmt"; "mirage-flow"; "mirage-device"; "result"] "mirage-protocols-lwt.opam";
  ]

let () =
  Pkg.describe ~opams ~metas "mirage-protocols" @@ fun c ->
  match Conf.pkg_name c with
  | "mirage-protocols" ->
    Ok [ Pkg.lib "pkg/META";
         Pkg.mllib "src/mirage-protocols.mllib" ]
  | "mirage-protocols-lwt" ->
    Ok [ Pkg.lib "pkg/META.lwt" ~dst:"META";
         Pkg.lib ~exts:Exts.interface "src/mirage_protocols_lwt" ]
  | other ->
    R.error_msgf "unknown package name: %s" other
