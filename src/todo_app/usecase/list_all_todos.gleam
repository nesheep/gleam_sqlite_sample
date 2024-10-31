import todo_app/domain/entity/todos.{type Todo}
import todo_app/error.{type AppError}

pub type Config(a) {
  Config(
    output_fn: fn(Result(List(Todo), AppError)) -> a,
    list_all_fn: fn() -> Result(List(Todo), AppError),
  )
}

pub fn new(cfg: Config(a)) -> fn() -> a {
  fn() { run(cfg) }
}

fn run(cfg: Config(a)) -> a {
  cfg.list_all_fn()
  |> cfg.output_fn
}
