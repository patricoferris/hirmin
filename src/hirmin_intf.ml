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
  val find : t -> 'a Key.t -> 'a option Lwt.t
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
