(* $MDX part-begin=fs *)
module Fs = struct
  type markdown = string [@@deriving irmin]
  type json = Irmin.Contents.Json_value.t [@@deriving irmin]
  type path = string list

  type 'a t =
    | Markdown : string list -> markdown t
    | Json : string list -> json t

  let key_to_path : type a. a t -> path = function
    | Markdown s -> s
    | Json s -> s

  let repr : type a. a t -> a Irmin.Type.t = function
    | Markdown _ -> markdown_t
    | Json _ -> json_t
end
(* $MDX part-end *)

(* $MDX part-begin=store *)
module Store = Hirmin.Make (Irmin_git_unix.FS.KV (Irmin.Contents.String)) (Fs)
(* $MDX part-end *)

(* $MDX part-begin=main *)
let main () =
  let open Lwt.Syntax in
  let config = Irmin_git.config "./store" in
  let* main = Store.main config in
  let info = Store.I.Info.none in
  let* () =
    Store.set_exn ~info main Fs.(Markdown [ "README.md" ]) "# Hello World\n"
  in
  let* () =
    Store.set_exn ~info main
      Fs.(Json [ "blob.json" ])
      (`O [ ("name", `String "Bactrian") ])
  in
  let* md = Store.find main Fs.(Markdown [ "README.md" ]) in
  let+ json = Store.find main Fs.(Json [ "blob.json" ]) in
  Option.iter print_endline md;
  Option.iter
    (fun v -> Fmt.pr "%a" (Irmin.Type.pp Irmin.Contents.Json_value.t) v)
    json
(* $MDX part-end *)

let () = Lwt_main.run @@ main ()
