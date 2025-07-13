import date_utils
import gleam/time/calendar as cal
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn is_between_test() {
  let date = cal.Date(2024, cal.December, 14)
  let start = cal.Date(2024, cal.November, 27)
  let end = cal.Date(2024, cal.December, 26)

  date_utils.is_between(date, start, end)
  |> should.equal(True)
}
