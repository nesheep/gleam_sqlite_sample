import app/todos/db
import app/util.{error_to_response, parse_int}
import app/web.{type Context}
import birl
import gleam/dynamic
import gleam/json
import gleam/result
import todo_app/domain/entity/todos.{type Todo}
import todo_app/error.{type AppError, BadRequest}
import todo_app/usecase/create_todo
import todo_app/usecase/delete_todo
import todo_app/usecase/list_all_todos
import todo_app/usecase/update_todo
import wisp.{type Request, type Response}

pub fn list_all(ctx: Context) -> Response {
  let output_fn = output_list_all
  let list_all_fn = fn() { db.list_all(ctx.db) }
  let cfg = list_all_todos.Config(output_fn:, list_all_fn:)
  let app = list_all_todos.new(cfg)
  app()
}

fn output_list_all(result: Result(List(Todo), AppError)) -> Response {
  case result {
    Ok(todos) ->
      json.object([#("todos", json.array(todos, todo_to_json))])
      |> json.to_string_builder
      |> wisp.json_response(200)
    Error(err) -> error_to_response(err)
  }
}

pub fn create(req: Request, ctx: Context) -> Response {
  use req_body <- wisp.require_json(req)
  let input_fn = fn() { input_create(req_body) }
  let output_fn = output_create
  let create_fn = db.create(ctx.db, _)
  let cfg = create_todo.Config(input_fn:, output_fn:, create_fn:)
  let app = create_todo.new(cfg)
  app()
}

fn input_create(body: dynamic.Dynamic) -> Result(String, AppError) {
  let decoder = dynamic.field("content", dynamic.string)
  decoder(body) |> result.replace_error(BadRequest)
}

fn output_create(result: Result(Int, AppError)) -> Response {
  case result {
    Ok(id) ->
      json.object([#("created_id", json.int(id))])
      |> json.to_string_builder
      |> wisp.json_response(201)
    Error(err) -> error_to_response(err)
  }
}

pub fn update(req: Request, ctx: Context, id: String) -> Response {
  use req_body <- wisp.require_json(req)
  let input_fn = fn() { input_update(id, req_body) }
  let output_fn = output_update
  let update_fn = fn(id, completed) { db.update(ctx.db, id, completed) }
  let cfg = update_todo.Config(input_fn:, output_fn:, update_fn:)
  let app = update_todo.new(cfg)
  app()
}

fn input_update(
  id: String,
  body: dynamic.Dynamic,
) -> Result(update_todo.Input, AppError) {
  use id <- result.try(parse_int(id))
  use completed <- result.try({
    let decoder = dynamic.field("completed", dynamic.bool)
    decoder(body) |> result.replace_error(BadRequest)
  })
  Ok(update_todo.Input(id:, completed:))
}

fn output_update(result: Result(Todo, AppError)) -> Response {
  case result {
    Ok(t) ->
      todo_to_json(t)
      |> json.to_string_builder
      |> wisp.json_response(200)
    Error(err) -> error_to_response(err)
  }
}

pub fn delete(ctx: Context, id: String) -> Response {
  let input_fn = fn() { parse_int(id) }
  let output_fn = output_delete
  let delete_fn = db.delete(ctx.db, _)
  let cfg = delete_todo.Config(input_fn:, output_fn:, delete_fn:)
  let app = delete_todo.new(cfg)
  app()
}

fn output_delete(result: Result(Int, AppError)) -> Response {
  case result {
    Ok(id) ->
      json.object([#("deleted_id", json.int(id))])
      |> json.to_string_builder
      |> wisp.json_response(200)
    Error(err) -> error_to_response(err)
  }
}

fn todo_to_json(t: Todo) -> json.Json {
  [
    #("id", json.int(t.id)),
    #("content", json.string(t.content)),
    #("completed", json.bool(t.completed)),
    #("created_at", json.string(t.created_at |> birl.to_iso8601)),
    #("updated_at", json.string(t.updated_at |> birl.to_iso8601)),
  ]
  |> json.object
}
