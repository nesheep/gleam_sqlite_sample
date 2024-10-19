import app/router
import app/web
import gleam/erlang/process
import mist
import sqlight
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let handle_request = fn(req) {
    use db <- sqlight.with_connection("/data/sample.db")
    let ctx = web.Context(db: db)
    router.handle_request(req, ctx)
  }

  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
