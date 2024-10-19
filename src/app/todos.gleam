import gleam/dynamic
import gleam/json
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
