import app/web.{type Context}
import birl.{type Time}
import gleam/dynamic
import gleam/int
import gleam/json
import gleam/result
import sqlight
import wisp.{type Request, type Response}

type Todo {
  Todo(id: Int, content: String, completed: Bool, created_at: Time)
}

fn to_json(t: Todo) -> json.Json {
  [
    #("id", json.int(t.id)),
    #("content", json.string(t.content)),
    #("completed", json.bool(t.completed)),
    #("created_at", json.string(t.created_at |> birl.to_iso8601)),
  ]
  |> json.object
}

pub fn handle_list_all(_req: Request, ctx: Context) -> Response {
  let todos = list_all(ctx.db)
  let res = [#("todos", json.array(todos, to_json))]
  let body = res |> json.object |> json.to_string_builder
  wisp.json_response(body, 200)
}

fn decode_create_request(body: dynamic.Dynamic) -> Result(String, Nil) {
  let decoder = dynamic.field("content", dynamic.string)
  decoder(body) |> result.nil_error
}

pub fn handle_create(req: Request, ctx: Context) -> Response {
  use req_body <- wisp.require_json(req)
  let result = {
    use content <- result.try(decode_create_request(req_body))
    create(ctx.db, content)
  }
  let res =
    result
    |> result.map(fn(id) { [#("created_id", json.int(id))] })
    |> result.map_error(fn(_) { [#("message", json.string("error"))] })
    |> result.unwrap_both
  let body = res |> json.object |> json.to_string_builder
  wisp.json_response(body, 201)
}

fn decode_update_request(body: dynamic.Dynamic) -> Result(Bool, Nil) {
  let decoder = dynamic.field("completed", dynamic.bool)
  decoder(body) |> result.nil_error
}

pub fn handle_update(req: Request, ctx: Context, id: String) -> Response {
  use req_body <- wisp.require_json(req)
  let result = {
    use id <- result.try(int.parse(id))
    use completed <- result.try(decode_update_request(req_body))
    update(ctx.db, id, completed)
  }
  let res =
    result
    |> result.map(to_json)
    |> result.map_error(fn(_) {
      [#("message", json.string("error"))] |> json.object
    })
    |> result.unwrap_both
  let body = res |> json.to_string_builder
  wisp.json_response(body, 200)
}

pub fn handle_delete(_req: Request, ctx: Context, id: String) -> Response {
  let result = {
    use id <- result.try(int.parse(id))
    delete(ctx.db, id)
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

fn time_decoder(data: dynamic.Dynamic) -> Result(Time, dynamic.DecodeErrors) {
  use str <- result.try(dynamic.string(data))
  case birl.parse(str <> "Z") {
    Ok(t) -> Ok(t)
    Error(_) -> Error([dynamic.DecodeError("birl.Time", "String", [])])
  }
}

fn todo_row_decoder() -> dynamic.Decoder(Todo) {
  dynamic.decode4(
    Todo,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, sqlight.decode_bool),
    dynamic.element(3, time_decoder),
  )
}

const list_all_sql = "
select id, content, completed, created_at
from todos
order by id desc
"

fn list_all(db: sqlight.Connection) -> List(Todo) {
  let assert Ok(rows) = sqlight.query(list_all_sql, db, [], todo_row_decoder())
  rows
}

const create_sql = "
insert into todos (content, completed)
values (?1, 0)
returning id
"

fn create(db: sqlight.Connection, content: String) -> Result(Int, Nil) {
  use rows <- result.then(
    sqlight.query(
      create_sql,
      on: db,
      with: [sqlight.text(content)],
      expecting: dynamic.element(0, dynamic.int),
    )
    |> result.nil_error,
  )

  let assert [id] = rows
  Ok(id)
}

const update_sql = "
update todos
set completed = ?1
where id = ?2
returning id, content, completed, created_at
"

fn update(db: sqlight.Connection, id: Int, completed: Bool) -> Result(Todo, Nil) {
  let assert Ok(rows) =
    sqlight.query(
      update_sql,
      db,
      [sqlight.bool(completed), sqlight.int(id)],
      todo_row_decoder(),
    )
  case rows {
    [t] -> Ok(t)
    _ -> Error(Nil)
  }
}

const delete_sql = "
delete from todos
where id = ?1
"

pub fn delete(db: sqlight.Connection, id: Int) -> Nil {
  let assert Ok(_) =
    sqlight.query(delete_sql, on: db, with: [sqlight.int(id)], expecting: Ok)
  Nil
}
