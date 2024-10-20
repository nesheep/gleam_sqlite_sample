import app/todos
import app/web.{type Context}
import gleam/http
import gleam/int
import gleam/json
import gleam/result
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

fn create_todo(req: Request, ctx: Context) -> Response {
  use req_body <- wisp.require_json(req)
  let result = {
    use content <- result.try(todos.decode_create_request(req_body))
    todos.create(ctx.db, content)
  }
  let res =
    result
    |> result.map(fn(id) { [#("created_id", json.int(id))] })
    |> result.map_error(fn(_) { [#("message", json.string("error"))] })
    |> result.unwrap_both
  let body = res |> json.object |> json.to_string_builder
  wisp.json_response(body, 201)
}

fn todo_item(req: Request, ctx: Context, id: String) -> Response {
  case req.method {
    http.Patch -> update_todo(req, ctx, id)
    http.Delete -> delete_todo(req, ctx, id)
    _ -> wisp.method_not_allowed([http.Patch])
  }
}

fn update_todo(req: Request, ctx: Context, id: String) -> Response {
  use req_body <- wisp.require_json(req)
  let result = {
    use id <- result.try(int.parse(id))
    use completed <- result.try(todos.decode_update_request(req_body))
    todos.update(ctx.db, id, completed)
  }
  let res =
    result
    |> result.map(todos.to_json)
    |> result.map_error(fn(_) {
      [#("message", json.string("error"))] |> json.object
    })
    |> result.unwrap_both
  let body = res |> json.to_string_builder
  wisp.json_response(body, 200)
}

fn delete_todo(_req: Request, ctx: Context, id: String) -> Response {
  let result = {
    use id <- result.try(int.parse(id))
    todos.delete(ctx.db, id)
    Ok(id)
  }
  let res =
    result
    |> result.map(fn(id) { [#("deleted_id", json.int(id))] })
    |> result.map_error(fn(_) { [#("message", json.string("error"))] })
    |> result.unwrap_both
  let body = res |> json.object |> json.to_string_builder
  wisp.json_response(body, 201)
}
