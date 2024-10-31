import gleam/int
import gleam/result
import todo_app/error.{type AppError, BadRequest, InternalError, NotFound}
import wisp.{type Response}

pub fn error_to_response(error: AppError) -> Response {
  case error {
    NotFound -> wisp.not_found()
    BadRequest -> wisp.bad_request()
    InternalError -> wisp.internal_server_error()
  }
}

pub fn parse_int(s: String) -> Result(Int, AppError) {
  int.parse(s) |> result.replace_error(BadRequest)
}
