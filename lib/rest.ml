let post ~env ~(sw : Eio.Switch.t) ~host ~path ~headers body =
  Easy_tls.run env @@ fun tls ->
  Eio.Net.with_tcp_connect ~host ~service:"https" env#net @@ fun connection ->
  let connection =
    Easy_tls.client_of_flow tls ~host connection 
  in
  let client =
    Cohttp_eio.Client.make
      ~https:(Some (Easy_tls.https ~authenticator:Easy_tls.null_auth))
      env#net
  in
  let full_path = Uri.of_string (String.concat "" ["https://"; host; path]) in
  let (http_response, body) =
      Cohttp_eio.Client.post client ~sw ~headers ~body full_path
  in
  Eio.Flow.shutdown connection `Send;
  match Http.Response.status http_response with
  | `OK ->
      Ok (Eio.Buf_read.(parse_exn take_all) body ~max_size:max_int)
  | status ->
      Error 
        ( (Http.Status.to_string status)
          ^ (Eio.Buf_read.(parse_exn take_all) body ~max_size:max_int) )
