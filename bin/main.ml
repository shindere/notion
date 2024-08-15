(* Overpass API:
  https://wiki.openstreetmap.org/wiki/Overpass_API
*)

let overpass_request =
  {| [out:json];
     node
       [amenity~"restaurant|fast_food|cafe"]
       (48.8412188, 2.3485422, 48.8444763, 2.3536409);
     out;
  |}

let () =
  let host = "overpass-api.de" in
  let path = "/api/interpreter" in
  let headers = Http.Header.of_list [] in
  let body = Cohttp_eio.Body.of_string overpass_request in
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  match (Notion.Rest.post ~env ~sw ~host ~path ~headers body) with
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
  | Error e -> print_string e; exit 1
