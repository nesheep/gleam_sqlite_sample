import app/error.{type AppError, BadRequest, NotFound, SqlightError}
import app/web.{type Context, parse_int}
import birl.{type Time}
import gleam/dynamic
import gleam/json
import gleam/result
import sqlight
import wisp.{type Request, type Response}

type Todo {
  Todo(
    id: Int,
    content: String,
    completed: Bool,
    created_at: Time,
    updated_at: Time,
  )
}

fn to_json(t: Todo) -> json.Json {
  [
    #("id", json.int(t.id)),
    #("content", json.string(t.content)),
    #("completed", json.bool(t.completed)),
    #("created_at", json.string(t.created_at |> birl.to_iso8601)),
    #("updated_at", json.string(t.updated_at |> birl.to_iso8601)),
  ]
  |> json.object
}

pub fn handle_list_all(ctx: Context) -> Response {
  let output_fn = fn(result: Result(List(Todo), AppError)) -> Response {
    case result {
      Ok(todos) ->
        json.object([#("todos", json.array(todos, to_json))])
        |> json.to_string_builder
        |> wisp.json_response(200)
      Error(err) -> web.error_to_response(err)
    }
  }

  let list_all_fn = fn() { list_all(ctx.db) }

  let app = new_list_all(ListAllCfg(output_fn:, list_all_fn:))
  app()
}

type ListAllCfg(a) {
  ListAllCfg(
    output_fn: fn(Result(List(Todo), AppError)) -> a,
    list_all_fn: fn() -> Result(List(Todo), AppError),
  )
}

fn new_list_all(cfg: ListAllCfg(a)) -> fn() -> a {
  fn() { run_list_all(cfg) }
}

fn run_list_all(cfg: ListAllCfg(a)) -> a {
  cfg.list_all_fn()
  |> cfg.output_fn
}

fn decode_create_request(body: dynamic.Dynamic) -> Result(String, AppError) {
  let decoder = dynamic.field("content", dynamic.string)
  decoder(body) |> result.replace_error(BadRequest)
}

pub fn handle_create(req: Request, ctx: Context) -> Response {
  use req_body <- wisp.require_json(req)

  let input_fn = fn() -> Result(String, AppError) {
    decode_create_request(req_body)
  }

  let output_fn = fn(result: Result(Int, AppError)) -> Response {
    case result {
      Ok(id) ->
        json.object([#("created_id", json.int(id))])
        |> json.to_string_builder
        |> wisp.json_response(201)
      Error(err) -> web.error_to_response(err)
    }
  }

  let create_fn = create(ctx.db, _)

  let app = new_create(CreateCfg(input_fn:, output_fn:, create_fn:))
  app()
}

type CreateCfg(a) {
  CreateCfg(
    input_fn: fn() -> Result(String, AppError),
    output_fn: fn(Result(Int, AppError)) -> a,
    create_fn: fn(String) -> Result(Int, AppError),
  )
}

fn new_create(cfg: CreateCfg(a)) -> fn() -> a {
  fn() { run_create(cfg) }
}

fn run_create(cfg: CreateCfg(a)) -> a {
  {
    use content <- result.try(cfg.input_fn())
    cfg.create_fn(content)
  }
  |> cfg.output_fn
}

fn decode_update_request(body: dynamic.Dynamic) -> Result(Bool, AppError) {
  let decoder = dynamic.field("completed", dynamic.bool)
  decoder(body) |> result.replace_error(BadRequest)
}

pub fn handle_update(req: Request, ctx: Context, id: String) -> Response {
  use req_body <- wisp.require_json(req)

  let input_fn = fn() -> Result(UpdateInput, AppError) {
    use id <- result.try(parse_int(id))
    use completed <- result.try(decode_update_request(req_body))
    Ok(UpdateInput(id:, completed:))
  }

  let output_fn = fn(result: Result(Todo, AppError)) -> Response {
    case result {
      Ok(t) ->
        to_json(t)
        |> json.to_string_builder
        |> wisp.json_response(200)
      Error(err) -> web.error_to_response(err)
    }
  }

  let update_fn = fn(id: Int, completed: Bool) { update(ctx.db, id, completed) }

  let app = new_update(UpdateCfg(input_fn:, output_fn:, update_fn:))
  app()
}

type UpdateCfg(a) {
  UpdateCfg(
    input_fn: fn() -> Result(UpdateInput, AppError),
    output_fn: fn(Result(Todo, AppError)) -> a,
    update_fn: fn(Int, Bool) -> Result(Todo, AppError),
  )
}

type UpdateInput {
  UpdateInput(id: Int, completed: Bool)
}

fn new_update(cfg: UpdateCfg(a)) -> fn() -> a {
  fn() { run_update(cfg) }
}

fn run_update(cfg: UpdateCfg(a)) -> a {
  {
    use input <- result.try(cfg.input_fn())
    cfg.update_fn(input.id, input.completed)
  }
  |> cfg.output_fn
}

pub fn handle_delete(ctx: Context, id: String) -> Response {
  let input_fn = fn() -> Result(Int, AppError) { parse_int(id) }

  let output_fn = fn(result: Result(Int, AppError)) -> Response {
    case result {
      Ok(id) ->
        json.object([#("deleted_id", json.int(id))])
        |> json.to_string_builder
        |> wisp.json_response(200)
      Error(err) -> web.error_to_response(err)
    }
  }

  let delete_fn = delete(ctx.db, _)

  let app = new_delete(DeleteCfg(input_fn:, output_fn:, delete_fn:))
  app()
}

type DeleteCfg(a) {
  DeleteCfg(
    input_fn: fn() -> Result(Int, AppError),
    output_fn: fn(Result(Int, AppError)) -> a,
    delete_fn: fn(Int) -> Result(Nil, AppError),
  )
}

fn new_delete(cfg: DeleteCfg(a)) -> fn() -> a {
  fn() { run_delete(cfg) }
}

fn run_delete(cfg: DeleteCfg(a)) -> a {
  {
    use id <- result.try(cfg.input_fn())
    use _ <- result.try(cfg.delete_fn(id))
    Ok(id)
  }
  |> cfg.output_fn
}

fn decode_time(data: dynamic.Dynamic) -> Result(Time, dynamic.DecodeErrors) {
  use str <- result.try(dynamic.string(data))
  case birl.parse(str <> "Z") {
    Ok(t) -> Ok(t)
    Error(_) -> Error([dynamic.DecodeError("birl.Time", "String", [])])
  }
}

fn todo_row_decoder() -> dynamic.Decoder(Todo) {
  dynamic.decode5(
    Todo,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, sqlight.decode_bool),
    dynamic.element(3, decode_time),
    dynamic.element(4, decode_time),
  )
}

const list_all_sql = "
select id, content, completed, created_at, updated_at
from todos
order by id desc
"

fn list_all(db: sqlight.Connection) -> Result(List(Todo), AppError) {
  sqlight.query(list_all_sql, db, [], todo_row_decoder())
  |> result.map_error(fn(err) { SqlightError(err) })
}

const create_sql = "
insert into todos (content)
values (?1)
returning id
"

fn create(db: sqlight.Connection, content: String) -> Result(Int, AppError) {
  use rows <- result.try(
    sqlight.query(
      create_sql,
      on: db,
      with: [sqlight.text(content)],
      expecting: dynamic.element(0, dynamic.int),
    )
    |> result.map_error(fn(err) { SqlightError(err) }),
  )
  let assert [id] = rows
  Ok(id)
}

const update_sql = "
update todos
set completed = ?1, updated_at = current_timestamp
where id = ?2
returning id, content, completed, created_at, updated_at
"

fn update(
  db: sqlight.Connection,
  id: Int,
  completed: Bool,
) -> Result(Todo, AppError) {
  use rows <- result.try(
    sqlight.query(
      update_sql,
      db,
      [sqlight.bool(completed), sqlight.int(id)],
      todo_row_decoder(),
    )
    |> result.map_error(fn(err) { SqlightError(err) }),
  )
  case rows {
    [t] -> Ok(t)
    _ -> Error(NotFound)
  }
}

const delete_sql = "
delete from todos
where id = ?1
returning id
"

pub fn delete(db: sqlight.Connection, id: Int) -> Result(Nil, AppError) {
  use rows <- result.try(
    sqlight.query(
      delete_sql,
      on: db,
      with: [sqlight.int(id)],
      expecting: dynamic.element(0, dynamic.int),
    )
    |> result.map_error(fn(err) { SqlightError(err) }),
  )
  case rows {
    [_] -> Ok(Nil)
    _ -> Error(NotFound)
  }
}
