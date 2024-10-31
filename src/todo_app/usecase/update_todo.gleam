import gleam/result
import todo_app/domain/entity/todos.{type Todo}
import todo_app/error.{type AppError}

pub type Config(a) {
  Config(
    input_fn: fn() -> Result(Input, AppError),
    output_fn: fn(Result(Todo, AppError)) -> a,
    update_fn: fn(Int, Bool) -> Result(Todo, AppError),
  )
}

pub type Input {
  Input(id: Int, completed: Bool)
}

pub fn new(cfg: Config(a)) -> fn() -> a {
  fn() { run(cfg) }
}

fn run(cfg: Config(a)) -> a {
  {
    use input <- result.try(cfg.input_fn())
    cfg.update_fn(input.id, input.completed)
  }
  |> cfg.output_fn
}
