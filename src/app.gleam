import app/router
import app/web
import env
import gleam/erlang/process
import mist
import sqlight
import wisp
import wisp/wisp_mist

pub fn main() {
  let assert Ok(env) = env.get()

  wisp.configure_logger()
  let secret_key_base = env.secret_key_base

  let handle_request = fn(req) {
    use db <- sqlight.with_connection("/data/" <> env.db_name)
    let ctx = web.Context(db: db)
    router.handle_request(req, ctx)
  }

  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(env.port)
    |> mist.start_http

  process.sleep_forever()
}
