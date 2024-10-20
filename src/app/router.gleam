import app/todos
import app/web.{type Context}
import gleam/http
import gleam/json
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> hello()
    ["todos"] -> todos(req, ctx)
    ["todos", id] -> todo_item(req, ctx, id)
    _ -> wisp.not_found()
  }
}

fn hello() -> Response {
  let message = "Hello, Gleam!"
  let res = [#("message", json.string(message))]
  let body = res |> json.object |> json.to_string_builder
  wisp.json_response(body, 200)
}

fn todos(req: Request, ctx: Context) -> Response {
  case req.method {
    http.Get -> todos.handle_list_all(req, ctx)
    http.Post -> todos.handle_create(req, ctx)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn todo_item(req: Request, ctx: Context, id: String) -> Response {
  case req.method {
    http.Patch -> todos.handle_update(req, ctx, id)
    http.Delete -> todos.handle_delete(req, ctx, id)
    _ -> wisp.method_not_allowed([http.Patch, http.Delete])
  }
}
