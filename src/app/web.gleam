import sqlight
import wisp.{type Request, type Response}

pub type Context {
  Context(db: sqlight.Connection)
}

pub fn middleware(
  req: Request,
  handle_request: fn(Request) -> Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  handle_request(req)
}
