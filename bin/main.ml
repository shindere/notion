(* Notion API: developers.notion.com,
  https://developers.notion.com/docs/getting-started
*)

let _base_url = "https://api.notion.com/"

let https ~authenticator =
  let tls_config = Tls.Config.client ~authenticator () in
  fun uri raw ->
  let host =
    (* Domain_name.host_exn (Domain_name.of_string "overpass-api.de") *)
      Uri.host uri
      |> Option.map (fun x -> Domain_name.(host_exn (of_string_exn x)))
    in
    Tls_eio.client_of_flow ?host tls_config raw

let overpass_request =
  String.concat "\n"
  [
    "[out:json];";
    "node";
    "  [amenity~\"restaurant|fast_food|cafe\"]";
    "  (48.8412188, 2.3485422, 48.8444763, 2.3536409);";
    "out;"
  ]                                      

let wget env sw host path headers body =
  Easy_tls.run env @@ fun tls ->
  Eio.Net.with_tcp_connect ~host ~service:"https" env#net @@ fun connection ->
  let connection =
    Easy_tls.client_of_flow tls ~host connection 
  in
  let null_auth ?ip:_ ~host:_ _ = Ok None in
  let client =
    Cohttp_eio.Client.make ~https:(Some (https ~authenticator:null_auth)) env#net
  in
  let (http_response, body) =
      Cohttp_eio.Client.post client ~sw ~headers ~body path
  in      
  Eio.Flow.shutdown connection `Send;
  match Http.Response.status http_response with
  | `OK ->
    Ok
      (Eio.Buf_read.(parse_exn take_all) body ~max_size:max_int)
    | status -> Error 
      ((Http.Status.to_string status) ^ (Eio.Buf_read.(parse_exn take_all) body ~max_size:max_int))

let _wget_notion id =
  let path = "https://api.notion.com/v1/blocks/" ^ id ^ "/children" in
  let token = Sys.getenv "NOTION_TOKEN" in
  let headers = (* Http.Header.of_list *)
  [
    "Notion-Version", "2022-06-28";
    "Authorization", ("Bearer " ^ token);
    "Content-type", "application/json";
  ]
  in
  (* wget "api.notion.com" path headers *)
  let url = path in
  let r = Ezcurl.get ~headers ~url () in
  match r with
  | Ok { code=200; body; _ } ->
    Ok body
  | Ok { body; _ } -> Error body
  | _ -> Error "ezcurl internal error"

let _ =
  let path = Uri.of_string "https://overpass-api.de/api/interpreter" in
  let headers = Http.Header.of_list [] in
  let body = Cohttp_eio.Body.of_string overpass_request in
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  match (wget env sw "overpass-api.de" path headers body) with
  | Ok s -> print_endline s
                          (*
                            let json_object = Yojson.Safe.from_string s in
    let open Yojson.Safe.Util in
    let string_member key obj = member key obj |> to_string in
    let results = member "results" json_object |> to_list in
    let p x =
      try (string_member "object" x = "block") &&
          (string_member "type" x = "child_page")
      with _ -> false
    in
    let subpages = List.filter p results in
    List.iter (fun block -> print_endline (string_member "id" block)) subpages
*)
  | Error e -> print_string e
