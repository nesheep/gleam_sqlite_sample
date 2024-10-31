import birl.{type Time}
import gleam/dynamic
import gleam/result
import sqlight
import todo_app/domain/entity/todos.{type Todo, Todo}
import todo_app/error.{type AppError, InternalError, NotFound}

const list_all_sql = "
select id, content, completed, created_at, updated_at
from todos
order by id desc
"

pub fn list_all(db: sqlight.Connection) -> Result(List(Todo), AppError) {
  sqlight.query(list_all_sql, db, [], todo_row_decoder())
  |> result.replace_error(InternalError)
}

const create_sql = "
insert into todos (content)
values (?1)
returning id
"

pub fn create(db: sqlight.Connection, content: String) -> Result(Int, AppError) {
  use rows <- result.try(
    sqlight.query(
      create_sql,
      on: db,
      with: [sqlight.text(content)],
      expecting: dynamic.element(0, dynamic.int),
    )
    |> result.replace_error(InternalError),
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

pub fn update(
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
    |> result.replace_error(InternalError),
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
    |> result.replace_error(InternalError),
  )
  case rows {
    [_] -> Ok(Nil)
    _ -> Error(NotFound)
  }
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
