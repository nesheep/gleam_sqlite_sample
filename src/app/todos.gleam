import gleam/dynamic
import gleam/json
import gleam/result
import sqlight

pub type Todo {
  Todo(id: Int, content: String, completed: Bool)
}

pub fn to_json(t: Todo) -> json.Json {
  [
    #("id", json.int(t.id)),
    #("content", json.string(t.content)),
    #("completed", json.bool(t.completed)),
  ]
  |> json.object
}

pub fn decode_create_request(body: dynamic.Dynamic) -> Result(String, Nil) {
  let decoder = dynamic.field("content", dynamic.string)
  decoder(body) |> result.nil_error
}

fn todo_row_decoder() -> dynamic.Decoder(Todo) {
  dynamic.decode3(
    Todo,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, sqlight.decode_bool),
  )
}

const list_all_sql = "
select id, content, completed
from todos
order by id desc
"

pub fn list_all(db: sqlight.Connection) -> List(Todo) {
  let assert Ok(rows) = sqlight.query(list_all_sql, db, [], todo_row_decoder())
  rows
}

const create_sql = "
insert into todos (content, completed)
values (?1, 0)
returning id
"

pub fn create(db: sqlight.Connection, content: String) -> Result(Int, Nil) {
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
