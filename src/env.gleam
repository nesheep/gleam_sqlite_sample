import envoy
import gleam/int
import gleam/result

pub type Env {
  Env(port: Int, db_name: String, secret_key_base: String)
}

pub fn get() -> Result(Env, Nil) {
  use port <- result.try(envoy.get("PORT"))
  use db_name <- result.try(envoy.get("DB_NAME"))
  use secret_key_base <- result.try(envoy.get("SECRET_KEY_BASE"))
  use port <- result.try(int.parse(port))
  Ok(Env(port:, db_name:, secret_key_base:))
}
