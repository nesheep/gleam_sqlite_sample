import app/todos/handler
import app/web.{type Context}
import gleam/http
import wisp.{type Request, type Response}

pub fn root(req: Request, ctx: Context) -> Response {
  case req.method {
    http.Get -> handler.list_all(ctx)
    http.Post -> handler.create(req, ctx)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

pub fn item(req: Request, ctx: Context, id: String) -> Response {
  case req.method {
    http.Patch -> handler.update(req, ctx, id)
    http.Delete -> handler.delete(ctx, id)
    _ -> wisp.method_not_allowed([http.Patch, http.Delete])
  }
}
