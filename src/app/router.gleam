import app/todos
import app/web.{type Context}
import gleam/json
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> hello()
    ["todos"] -> todos.root(req, ctx)
    ["todos", id] -> todos.item(req, ctx, id)
    _ -> wisp.not_found()
  }
}

fn hello() -> Response {
  let message = "Hello, Gleam!"
  let res = [#("message", json.string(message))]
  let body = res |> json.object |> json.to_string_builder
  wisp.json_response(body, 200)
}
