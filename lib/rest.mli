(** Performs an HTTP POST request. *)
val post :
     env:< clock : [> float Eio.Time.clock_ty ] Eio.Resource.t;
           fs : [> Eio.Fs.dir_ty ] Eio.Path.t;
           mono_clock : [> Eio.Time.Mono.ty ] Eio.Resource.t;
           net : [> [> `Generic ] Eio.Net.ty ] Eio.Resource.t;
           secure_random : [> Eio.Flow.source_ty ] Eio.Resource.t; .. >
  -> sw:Eio.Switch.t
  -> host:string
  -> path:string
  -> headers:Http.Header.t
  -> Cohttp_eio.Body.t
  -> (string, string) result
