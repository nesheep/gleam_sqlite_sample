import birl.{type Time}

pub type Todo {
  Todo(
    id: Int,
    content: String,
    completed: Bool,
    created_at: Time,
    updated_at: Time,
  )
}
