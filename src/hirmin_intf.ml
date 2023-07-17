module type Key = sig
  type 'contents t
  (** Keys that also tell us what type of contents will be returned *)

  type path
  (** Keys as specified by the underlying Irmin store *)

  val key_to_path : _ t -> path
  (** Convert a key to an Irmin path *)

  val repr : 'contents t -> 'contents Repr.t
  (** Runtime representations of the different types of content that can
      be returned. *)
end

module type S = sig
  type t
  (** A hirmin store *)

  module I : Irmin.S
  (** The underlying Irmin store *)

  module Key : Key with type path = I.Path.t
  (** Keys for the hirmin store *)

  val main : Irmin.config -> t Lwt.t
  (** The main branch of the store *)

  val set_exn : info:I.Info.f -> t -> 'a Key.t -> 'a -> unit Lwt.t
  (** Like Irmin's [set_exn] but now the value type depends on the key. *)

  val find : t -> 'a Key.t -> 'a option Lwt.t
  (** Like Irmin's [find] except the value type depends on the key. *)

  module Tree : sig
    type t
    (** Like Irmin trees but with the keys *)

    val empty : unit -> t
    (** The empty tree *)

    val add : ?metadata:I.metadata -> t -> 'a Key.t -> 'a -> t Lwt.t
    (** Add a new key-value pair to a tree *)

    val mem : t -> 'a Key.t -> bool Lwt.t
    (** Check for membership *)

    val remove : t -> 'a Key.t -> t Lwt.t
    (** Remove a key from a tree *)
  end

  val set_tree_exn :
    ?clear:bool ->
    ?retries:int ->
    ?allow_empty:bool ->
    ?parents:I.commit list ->
    info:I.Info.f ->
    t ->
    'a Key.t ->
    Tree.t ->
    unit Lwt.t
  (** Like Irmin's [set_tree_exn] only using a the key API. *)
end

module type Maker = functor
  (I : Irmin.S with type Schema.Contents.t = string)
  (K : Key with type path = I.Path.t)
  -> S with type 'a Key.t = 'a K.t

module type Intf = sig
  module type Key = Key
  module type S = S

  module Make : Maker
end
