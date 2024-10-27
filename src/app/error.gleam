import sqlight

pub type AppError {
  NotFound
  BadRequest
  SqlightError(sqlight.Error)
}
