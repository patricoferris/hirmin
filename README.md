hirmin
------

Somewhat heterogeneous Irmin stores.

Hirmin provides functors to build heterogeneous key-value stores with Irmin. Keys in hirmin are GADTs that also tell us what kind of thing to be expected coming back from the store. There are two pain points:

1. You must specify quite a lot more in your `Key` module, things that can't be derived directly. You must also specify how your keys can be converted to an Irmin
path (most commonly a `string list`).
2. Irmin's merge function is just a function of the mergeable datatype, but now a little information about our contents (namely its type) lives with the key but there is no way without changing Irmin or also storing the key with the value to get the key to the merge function to disambiguate the kinds of things stored. This means you can't do any fancy merging.

## Example

Some markdown and JSON files stored in a git-compatible repository.

<!-- $MDX file=example/main.ml,part=fs -->
```ocaml
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
```

With this we can create a new Irmin-like store.

<!-- $MDX file=example/main.ml,part=store -->
```ocaml
module Store = Hirmin.Make (Irmin_git_unix.FS.KV (Irmin.Contents.String)) (Fs)
```

And finally we can use it to store values.

<!-- $MDX file=example/main.ml,part=main -->
```ocaml
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
```
