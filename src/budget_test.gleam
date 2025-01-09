import gleam/dynamic/decode
import gleam/int
import gleam/option
import gleam/string
import rada/date as d

pub type User {
  User(id: String, name: String)
}

fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(User(id:, name:))
}

pub type Category {
  Category(
    id: String,
    name: String,
    target: option.Option(Target),
    inflow: Bool,
  )
}

pub type Target {
  Monthly(target: Money)
  Custom(target: Money, date: MonthInYear)
}

pub type MonthInYear {
  MonthInYear(month: Int, year: Int)
}

pub type Allocation {
  Allocation(id: String, amount: Money, category_id: String, date: Cycle)
}

pub type Cycle {
  Cycle(year: Int, month: d.Month)
}

pub type Transaction {
  Transaction(
    id: String,
    date: d.Date,
    payee: String,
    category_id: String,
    value: Money,
  )
}

pub type Money {
  //s - signature, b - base
  Money(s: Int, b: Int, is_neg: Bool)
}

pub fn money_sum(a: Money, b: Money) -> Money {
  let sign_a = case a.is_neg {
    False -> 1
    True -> -1
  }
  let sign_b = case b.is_neg {
    False -> 1
    True -> -1
  }
  let a_cents = { a.s * 100 + a.b } * sign_a
  let b_cents = { b.s * 100 + b.b } * sign_b
  Money(
    { a_cents + b_cents } / 100 |> int.absolute_value,
    { a_cents + b_cents } % 100 |> int.absolute_value,
    { a_cents + b_cents } < 0,
  )
}

pub fn calculate_current_cycle() -> Cycle {
  let today = d.today()
  let last_day = 26
  let cycle = Cycle(d.year(today), today |> d.month)
  case d.day(today) > last_day {
    False -> cycle
    True -> cycle_increase(cycle)
  }
}

pub fn cycle_decrease(c: Cycle) -> Cycle {
  let mon_num = d.month_to_number(c.month)
  case mon_num {
    1 -> Cycle(c.year - 1, d.Dec)
    _ -> Cycle(c.year, d.number_to_month(mon_num - 1))
  }
}

pub fn cycle_increase(c: Cycle) -> Cycle {
  let mon_num = d.month_to_number(c.month)
  case mon_num {
    12 -> Cycle(c.year + 1, d.Jan)
    _ -> Cycle(c.year, d.number_to_month(mon_num + 1))
  }
}

pub fn divide_money(m: Money, d: Int) -> Money {
  Money(m.s / d, m.b / d, m.is_neg)
}

pub fn int_to_money(i: Int) -> Money {
  Money(i |> int.absolute_value, 0, i < 0)
}

pub fn negate(m: Money) -> Money {
  Money(..m, is_neg: True)
}

pub fn float_to_money(i: Int, c: Int) -> Money {
  Money(i |> int.absolute_value, c, i < 0)
}

pub fn string_to_money(raw: String) -> Money {
  let #(is_neg, s) = case string.slice(raw, 0, 1) {
    "-" -> #(True, string.slice(raw, 1, string.length(raw)))
    _ -> #(False, raw)
  }
  case string.replace(s, ",", ".") |> string.split(".") {
    [s, b, ..] ->
      case
        int.parse(s),
        b |> string.pad_end(2, "0") |> string.slice(0, 2) |> int.parse
      {
        Ok(s), Ok(b) -> Money(s, b, is_neg)
        _, _ -> Money(0, 0, is_neg)
      }
    [s, ..] ->
      case int.parse(s) {
        Ok(s) -> Money(s, 0, is_neg)
        _ -> Money(0, 0, is_neg)
      }
    _ -> Money(0, 0, is_neg)
  }
}

pub fn money_to_string(m: Money) -> String {
  let sign = sign_symbols(m)
  sign <> "€" <> money_to_string_no_sign(m)
}

pub fn money_to_string_no_sign(m: Money) -> String {
  m.s |> int.to_string <> "." <> m.b |> int.to_string
}

pub fn money_to_string_no_currency(m: Money) -> String {
  let sign = sign_symbols(m)
  sign <> m.s |> int.to_string <> "." <> m.b |> int.to_string
}

fn sign_symbols(m: Money) -> String {
  case m.is_neg {
    True ->
      case is_zero(m) {
        True -> ""
        False -> "-"
      }
    False -> ""
  }
}

pub fn is_neg(m: Money) -> Bool {
  m.is_neg
}

pub fn is_zero(m: Money) -> Bool {
  case m.s, m.b {
    0, 0 -> True
    _, _ -> False
  }
}

pub fn is_zero_int(m: Money) -> Bool {
  m.s == 0
}
// pub fn allocations(cycle: Cycle) -> List(Allocation) {
//   let c = Cycle(2024, d.Dec)
//   [
//     Allocation(id: "1", amount: int_to_money(80), category_id: "1", date: c),
//     Allocation(id: "2", amount: int_to_money(120), category_id: "2", date: c),
//     Allocation(id: "3", amount: int_to_money(150), category_id: "3", date: c),
//     Allocation(
//       id: "4",
//       amount: float_to_money(100, 2),
//       category_id: "4",
//       date: c,
//     ),
//     Allocation(
//       id: "5",
//       amount: float_to_money(150, 2),
//       category_id: "5",
//       date: c,
//     ),
//     Allocation(
//       id: "6",
//       amount: float_to_money(500, 2),
//       category_id: "6",
//       date: c,
//     ),
//   ]
//   // |> list.filter(fn(a) { a.date == cycle })
// }

// pub fn categories() -> List(Category) {
//   [
//     Category(
//       id: "1",
//       name: "Subscriptions",
//       target: option.Some(Monthly(float_to_money(60, 0))),
//       inflow: False,
//     ),
//     Category(
//       id: "2",
//       name: "Shopping",
//       target: option.Some(Monthly(float_to_money(40, 0))),
//       inflow: False,
//     ),
//     Category(
//       id: "3",
//       name: "Goals",
//       target: option.Some(Custom(float_to_money(150, 0), MonthInYear(2, 2025))),
//       inflow: False,
//     ),
//     Category(id: "4", name: "Vacation", target: option.None, inflow: False),
//     Category(
//       id: "5",
//       name: "Entertainment",
//       target: option.Some(Monthly(float_to_money(200, 0))),
//       inflow: False,
//     ),
//     Category(
//       id: "6",
//       name: "Groceries",
//       target: option.Some(Monthly(float_to_money(500, 0))),
//       inflow: False,
//     ),
//     Category(
//       id: "7",
//       name: "Ready to assign",
//       target: option.None,
//       inflow: True,
//     ),
//   ]
// }

// pub fn transactions() -> List(Transaction) {
//   [
//     Transaction(
//       id: "1",
//       date: d.from_calendar_date(2025, d.Jan, 1),
//       payee: "Amazon",
//       category_id: "5",
//       value: float_to_money(-10, 0),
//     ),
//     Transaction(
//       id: "1",
//       date: d.from_calendar_date(2024, d.Dec, 2),
//       payee: "Amazon",
//       category_id: "5",
//       value: float_to_money(-50, 0),
//     ),
//     Transaction(
//       id: "2",
//       date: d.from_calendar_date(2024, d.Dec, 2),
//       payee: "Bauhaus",
//       category_id: "5",
//       value: float_to_money(-50, 0),
//     ),
//     Transaction(
//       id: "3",
//       date: d.from_calendar_date(2024, d.Dec, 2),
//       payee: "Rewe",
//       category_id: "6",
//       value: float_to_money(-50, 0),
//     ),
//     Transaction(
//       id: "4",
//       date: d.from_calendar_date(2024, d.Dec, 2),
//       payee: "Vodafone",
//       category_id: "1",
//       value: float_to_money(-50, 0),
//     ),
//     Transaction(
//       id: "5",
//       date: d.from_calendar_date(2024, d.Dec, 2),
//       payee: "Steam",
//       category_id: "5",
//       value: float_to_money(-50, 0),
//     ),
//     Transaction(
//       id: "6",
//       date: d.from_calendar_date(2024, d.Dec, 2),
//       payee: "Duo",
//       category_id: "1",
//       value: float_to_money(-50, 60),
//     ),
//     Transaction(
//       id: "7",
//       date: d.from_calendar_date(2024, d.Dec, 2),
//       payee: "O2",
//       category_id: "1",
//       value: float_to_money(-50, 0),
//     ),
//     Transaction(
//       id: "8",
//       date: d.from_calendar_date(2024, d.Dec, 2),
//       payee: "Trade Republic",
//       category_id: "7",
//       value: float_to_money(1000, 0),
//     ),
//     Transaction(
//       id: "8",
//       date: d.from_calendar_date(2024, d.Nov, 27),
//       payee: "O2",
//       category_id: "1",
//       value: float_to_money(-1, 50),
//     ),
//     Transaction(
//       id: "8",
//       date: d.from_calendar_date(2024, d.Nov, 26),
//       payee: "O2",
//       category_id: "1",
//       value: float_to_money(-1, 50),
//     ),
//   ]
// }
