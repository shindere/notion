type t = Tls.Config.client

let run env op =
  Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env @@
  fun () ->
    let authenticator =
      X509_eio.authenticator (`Ca_dir Eio.Path.(env#fs/"/etc"/"ssl"/"certs"))
    in
    op (Tls.Config.client ~authenticator ())

let client_of_flow t ~host connection =
  Tls_eio.client_of_flow 
    ~host:(Domain_name.of_string_exn host |> Domain_name.host_exn)
    t
    connection

let null_auth ?ip:_ ~host:_ _ = Ok None

let https ~authenticator =
  let tls_config = Tls.Config.client ~authenticator () in
  fun uri raw ->
  let host =
    Uri.host uri
    |> Option.map (fun x -> Domain_name.(host_exn (of_string_exn x)))
  in
  Tls_eio.client_of_flow ?host tls_config raw
