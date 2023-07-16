include Hirmin_intf

module Make
    (I : Irmin.S with type Schema.Contents.t = string)
    (K : Key with type path = I.Path.t) =
struct
  module Key = K
  module I = I

  type t = I.t

  let main config =
    let open Lwt.Infix in
    I.Repo.v config >>= fun v -> I.main v

  let to_string r k = Irmin.Type.to_string r k

  let set_exn ~info t k v =
    let key = K.key_to_path k in
    let v = to_string (K.repr k) v in
    I.set_exn ~info t key v

  let find t k =
    let open Lwt.Infix in
    let key = K.key_to_path k in
    let f v = Irmin.Type.(of_string (K.repr k)) v |> Result.get_ok in
    I.find t key >|= fun v -> Option.map f v
end
