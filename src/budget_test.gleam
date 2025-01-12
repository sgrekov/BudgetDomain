import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/option
import gleam/string
import rada/date as d

pub type User {
  User(id: String, name: String)
}

pub fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(User(id:, name:))
}

pub type CategoryGroup {
  CategoryGroup(id: String, name: String, position: Int)
}

pub fn category_group_decoder() -> decode.Decoder(CategoryGroup) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use position <- decode.field("position", decode.int)
  decode.success(CategoryGroup(id:, name:, position:))
}

pub type Category {
  Category(
    id: String,
    name: String,
    target: option.Option(Target),
    inflow: Bool,
  )
}

pub fn category_suggestions_decoder() -> decode.Decoder(
  dict.Dict(String, Category),
) {
  decode.dict(decode.string, category_decoder())
}

pub fn category_decoder() -> decode.Decoder(Category) {
  {
    use id <- decode.field("id", decode.string)
    use name <- decode.field("name", decode.string)
    use target <- decode.field("target", decode.optional(target_decoder()))
    use inflow <- decode.field("inflow", decode.bool)
    decode.success(Category(id, name, target, inflow))
  }
}

pub type Target {
  Monthly(target: Money)
  Custom(target: Money, date: MonthInYear)
}

pub fn target_decoder() -> decode.Decoder(Target) {
  let monthly_decoder = {
    use money <- decode.field("money", money_decoder())
    decode.success(Monthly(money))
  }

  let custom_decoder = {
    use money <- decode.field("money", money_decoder())
    use date <- decode.field("date", month_decoder())
    decode.success(Custom(money, date))
  }

  let target_decoder = {
    use tag <- decode.field("type", decode.string)
    case tag {
      "monthly" -> monthly_decoder
      _ -> custom_decoder
    }
  }
  target_decoder
}

pub type MonthInYear {
  MonthInYear(month: Int, year: Int)
}

pub fn month_decoder() -> decode.Decoder(MonthInYear) {
  {
    use month <- decode.field("month", decode.int)
    use year <- decode.field("year", decode.int)
    decode.success(MonthInYear(month, year))
  }
}

pub type Allocation {
  Allocation(id: String, amount: Money, category_id: String, date: Cycle)
}

pub fn allocation_decoder() -> decode.Decoder(Allocation) {
  let allocation_decoder = {
    use id <- decode.field("id", decode.string)
    use amount <- decode.field("amount", money_decoder())
    use category_id <- decode.field("category_id", decode.string)
    use date <- decode.field("date", cycle_decoder())
    decode.success(Allocation(id, amount, category_id, date))
  }
  allocation_decoder
}

pub type Cycle {
  Cycle(year: Int, month: d.Month)
}

pub fn cycle_decoder() -> decode.Decoder(Cycle) {
  let cycle_decoder = {
    use month <- decode.field("month", decode.int)
    use year <- decode.field("year", decode.int)
    decode.success(Cycle(year, month |> d.number_to_month))
  }
  cycle_decoder
}

pub type Transaction {
  Transaction(
    id: String,
    date: d.Date,
    payee: String,
    category_id: String,
    value: Money,
    user_id: String,
  )
}

pub fn transaction_decoder() -> decode.Decoder(Transaction) {
  {
    use id <- decode.field("id", decode.string)
    use date <- decode.field("date", decode.int)
    use payee <- decode.field("payee", decode.string)
    use category_id <- decode.field("category_id", decode.string)
    use value <- decode.field("value", money_decoder())
    use user_id <- decode.field("user_id", decode.string)
    decode.success(Transaction(
      id,
      d.from_rata_die(date),
      payee,
      category_id,
      value,
      user_id,
    ))
  }
}

pub type Money {
  //s - signature, b - base
  Money(s: Int, b: Int, is_neg: Bool)
}

pub fn money_decoder() -> decode.Decoder(Money) {
  let money_decoder = {
    use s <- decode.field("s", decode.int)
    use b <- decode.field("b", decode.int)
    use is_neg <- decode.field("is_neg", decode.bool)
    decode.success(Money(s, b, is_neg))
  }
  money_decoder
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

pub fn is_zero(m: Money) -> Bool {
  case m.s, m.b {
    0, 0 -> True
    _, _ -> False
  }
}

pub fn is_zero_int(m: Money) -> Bool {
  m.s == 0
}
