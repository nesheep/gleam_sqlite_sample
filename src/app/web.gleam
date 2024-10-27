import app/error.{type AppError, BadRequest, NotFound, SqlightError}
import gleam/int
import gleam/result
import sqlight
import wisp.{type Response}

pub type Context {
  Context(db: sqlight.Connection)
}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  handle_request(req)
}

pub fn error_to_response(error: AppError) -> Response {
  case error {
    NotFound -> wisp.not_found()
    BadRequest -> wisp.bad_request()
    SqlightError(_) -> wisp.internal_server_error()
  }
}

pub fn parse_int(s: String) -> Result(Int, AppError) {
  int.parse(s) |> result.replace_error(BadRequest)
}
