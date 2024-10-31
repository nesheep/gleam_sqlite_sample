import gleam/result
import todo_app/error.{type AppError}

pub type Config(a) {
  Config(
    input_fn: fn() -> Result(Int, AppError),
    output_fn: fn(Result(Int, AppError)) -> a,
    delete_fn: fn(Int) -> Result(Nil, AppError),
  )
}

pub fn new(cfg: Config(a)) -> fn() -> a {
  fn() { run(cfg) }
}

fn run(cfg: Config(a)) -> a {
  {
    use id <- result.try(cfg.input_fn())
    use _ <- result.try(cfg.delete_fn(id))
    Ok(id)
  }
  |> cfg.output_fn
}
