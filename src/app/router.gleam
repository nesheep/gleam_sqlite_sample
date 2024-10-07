import app/web.{type Context}
import gleam/json
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, _ctx: Context) -> Response {
  use req <- web.middleware(req)

  let name = case wisp.path_segments(req) {
    [name] -> name
    _ -> "Taro"
  }

  let message = "Hello, " <> name <> "!"

  let body =
    [#("message", json.string(message))]
    |> json.object
    |> json.to_string_builder

  wisp.json_response(body, 200)
}
