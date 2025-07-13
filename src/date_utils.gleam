import gleam/int
import gleam/order
import gleam/result
import gleam/string
import gleam/time/calendar as cal
import gleam/time/duration
import gleam/time/timestamp as t

pub fn to_date_string(d: cal.Date) -> String {
  d.day |> int.to_string |> string.pad_start(2, "0")
  <> "."
  <> d.month |> cal.month_to_int |> int.to_string |> string.pad_start(2, "0")
  <> "."
  <> d.year |> int.to_string
}

pub fn to_timestamp_string(t: t.Timestamp) -> String {
  t |> timestamp_to_date |> to_date_string
}

pub fn to_date_string_input(d: cal.Date) -> String {
  // d.format(value, "yyyy-MM-dd")
  d.year |> int.to_string
  <> "-"
  <> d.month |> cal.month_to_int |> int.to_string |> string.pad_start(2, "0")
  <> "-"
  <> d.day |> int.to_string |> string.pad_start(2, "0")
}

pub fn timestamp_to_date(ts: t.Timestamp) -> cal.Date {
  let #(date, _) = t.to_calendar(ts, cal.utc_offset)
  date
}

pub fn timestamp_string_input(t: t.Timestamp) -> String {
  t |> timestamp_to_date |> to_date_string_input
}

pub fn date_to_timestamp(date: cal.Date) -> t.Timestamp {
  t.from_calendar(date, cal.TimeOfDay(0, 0, 0, 0), cal.utc_offset)
}

pub fn timestamp_date_to_string(ts: t.Timestamp) -> String {
  let #(date, _) = t.to_calendar(ts, cal.utc_offset)
  to_date_string(date)
}

pub fn timestamp_to_date_string_input(t: t.Timestamp) -> String {
  t |> timestamp_to_date |> to_date_string_input
}

// pub fn from_date_string(date_str: String) -> Result(d.Date, String) {
//   d.from_iso_string(date_str)
// }

pub fn string_to_date(date: String) -> Result(cal.Date, String) {
  date
  |> string.split("-")
  |> list_to_date
}

fn list_to_date(list: List(String)) -> Result(cal.Date, String) {
  case list {
    [year, month, day] ->
      int.base_parse(year, 10)
      |> result.map_error(fn(_) { "Invalid year" })
      |> result.try(fn(y) {
        int.base_parse(month, 10)
        |> result.map_error(fn(_) { "Invalid month" })
        |> result.try(fn(m_int) {
          let month2 = month_by_number(m_int)
          int.base_parse(day, 10)
          |> result.map_error(fn(_) { "Invalid day" })
          |> result.map(fn(d) { cal.Date(y, month2, d) })
        })
      })
    _ -> Error("Invalid date format")
  }
}

pub fn month_to_name(month: cal.Month) -> String {
  cal.month_to_string(month)
}

pub fn days_in_month(month: cal.Month) -> Int {
  case month {
    cal.January -> 31
    cal.February -> 28
    cal.March -> 31
    cal.April -> 30
    cal.May -> 31
    cal.June -> 30
    cal.July -> 31
    cal.August -> 31
    cal.September -> 30
    cal.October -> 31
    cal.November -> 30
    cal.December -> 31
  }
}

pub fn month_by_number(month: Int) -> cal.Month {
  cal.month_from_int(month) |> result.unwrap(cal.January)
}

pub fn date_string_to_month(date_str: String) -> cal.Month {
  string_to_date(date_str)
  |> result.map(fn(d) { d.month })
  |> result.unwrap(cal.January)
}

pub fn is_between(d: cal.Date, start: cal.Date, end: cal.Date) -> Bool {
  let t = d |> date_to_timestamp
  let start_t = start |> date_to_timestamp
  let end_date_t = end |> date_to_timestamp

  case t.compare(t, start_t) {
    order.Eq | order.Gt ->
      case t.compare(t, end_date_t) {
        order.Eq | order.Lt -> True
        order.Gt -> False
      }
    order.Lt -> False
  }
}
