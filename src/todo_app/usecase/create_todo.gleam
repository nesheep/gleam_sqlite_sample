import gleam/result
import todo_app/error.{type AppError}

pub type Config(a) {
  Config(
    input_fn: fn() -> Result(String, AppError),
    output_fn: fn(Result(Int, AppError)) -> a,
    create_fn: fn(String) -> Result(Int, AppError),
  )
}

pub fn new(cfg: Config(a)) -> fn() -> a {
  fn() { run(cfg) }
}

fn run(cfg: Config(a)) -> a {
  {
    use content <- result.try(cfg.input_fn())
    cfg.create_fn(content)
  }
  |> cfg.output_fn
}
