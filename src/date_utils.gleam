import budget_shared as m
import gleam/int
import gleam/result
import gleam/string
import rada/date as d

pub fn to_date_string(value: d.Date) -> String {
  d.format(value, "dd.MM.yyyy")
}

pub fn to_date_string_input(value: d.Date) -> String {
  d.format(value, "yyyy-MM-dd")
}

// pub fn from_date_string(date_str: String) -> Result(d.Date, String) {
//   d.from_iso_string(date_str)
// }

pub fn string_to_date(date: String) -> Result(d.Date, String) {
  date
  |> string.split("-")
  |> list_to_date
}

fn list_to_date(list: List(String)) -> Result(d.Date, String) {
  // case list {
  //   [year, month, day] ->
  //     case int.base_parse(year, 10) {
  //       Ok(y) -> {
  //         case int.base_parse(month, 10) {
  //           Ok(m_int) -> {
  //             let month2 = month_by_number(m_int)
  //             case int.base_parse(day, 10) {
  //               Ok(d) -> Ok(d.from_calendar_date(y, month2, d))
  //               _ -> Error("Invalid day")
  //             }
  //           }
  //           _ -> Error("Invalid month")
  //         }
  //       }
  //       _ -> Error("Invalid year")
  //     }
  //   _ -> Error("Invalid date format")
  // }
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
          |> result.map(fn(d) { d.from_calendar_date(y, month2, d) })
        })
      })
    _ -> Error("Invalid date format")
  }
}

pub fn month_to_name(month: d.Month) -> String {
  case month {
    d.Jan -> "January"
    d.Feb -> "February"
    d.Mar -> "March"
    d.Apr -> "April"
    d.May -> "May"
    d.Jun -> "June"
    d.Jul -> "July"
    d.Aug -> "August"
    d.Sep -> "September"
    d.Oct -> "October"
    d.Nov -> "November"
    d.Dec -> "December"
  }
}

pub fn days_in_month(_: Int, month: d.Month) -> Int {
  case month {
    d.Jan -> 31
    d.Feb -> 28
    d.Mar -> 31
    d.Apr -> 30
    d.May -> 31
    d.Jun -> 30
    d.Jul -> 31
    d.Aug -> 31
    d.Sep -> 30
    d.Oct -> 31
    d.Nov -> 30
    d.Dec -> 31
  }
}

pub fn month_by_number(month: Int) -> d.Month {
  case month {
    1 -> d.Jan
    2 -> d.Feb
    3 -> d.Mar
    4 -> d.Apr
    5 -> d.May
    6 -> d.Jun
    7 -> d.Jul
    8 -> d.Aug
    9 -> d.Sep
    10 -> d.Oct
    11 -> d.Nov
    12 -> d.Dec
    _ -> d.Jan
  }
}

fn date_to_month(d: d.Date) -> m.MonthInYear {
  m.MonthInYear(d |> d.month_number, d |> d.year)
}

pub fn date_string_to_month(date_str: String) -> m.MonthInYear {
  string_to_date(date_str)
  |> result.map(fn(d) { date_to_month(d) })
  |> result.unwrap(m.MonthInYear(0, 0))
}

pub fn month_in_year_to_str(month_in_year: m.MonthInYear) -> String {
  let date2 =
    d.from_calendar_date(
      month_in_year.year,
      month_by_number(month_in_year.month),
      1,
    )
  d.format(date2, "yyyy-MM-dd")
}
