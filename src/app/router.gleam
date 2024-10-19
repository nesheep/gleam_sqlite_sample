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
    http.Get -> list_all_todos(req, ctx)
    http.Post -> create_todo(req, ctx)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn list_all_todos(_req: Request, ctx: Context) -> Response {
  let todos = todos.list_all(ctx.db)
  let res = [#("todos", json.array(todos, todos.to_json))]
  let body = res |> json.object |> json.to_string_builder
  wisp.json_response(body, 200)
}

fn create_todo(_req: Request, _ctx: Context) -> Response {
  let res = [#("message", json.string("create todo"))]
  let body = res |> json.object |> json.to_string_builder
  wisp.json_response(body, 201)
}
