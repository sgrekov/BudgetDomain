// import gleam/json
import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/io
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
    group_id: String,
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
    use group_id <- decode.field("group_id", decode.string)
    decode.success(Category(id, name, target, inflow, group_id))
  }
}

// pub fn category_encode(cat: Category) -> json.Json {
//   json.object([
//     #("id", json.string(cat.id)),
//     #("name", json.string(cat.name)),
//     // #("target", json.nullable(cat.target, of: target_encode)),
//     #("inflow", json.bool(cat.inflow)),
//     #("group_id", json.string(cat.group_id)),
//   ])
// }

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
  //stored as cents
  Money(value: Int)
}

pub fn money_decoder() -> decode.Decoder(Money) {
  let money_decoder = {
    use value <- decode.field("money_value", decode.int)
    decode.success(Money(value))
  }
  money_decoder
}

pub fn money_sum(a: Money, b: Money) -> Money {
  Money(a.value + b.value)
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
  Money(m.value / d)
}

pub fn euro_int_to_money(i: Int) -> Money {
  Money(i * 100)
}

// pub fn negate(m: Money) -> Money {
//   Money(..m, is_neg: True)
// }

// pub fn positivate(m: Money) -> Money {
//   Money(..m, is_neg: False)
// }

// pub fn float_to_money(i: Int, c: Int) -> Money {
//   Money(i |> int.absolute_value, c, i < 0)
// }

pub fn string_to_money(raw: String) -> Money {
  let #(is_neg, s) = case string.slice(raw, 0, 1) {
    "-" -> #(-1, string.slice(raw, 1, string.length(raw)))
    _ -> #(1, raw)
  }
  case string.replace(s, ",", ".") |> string.split(".") {
    [s, b, ..] -> {
      // io.debug("s: " <> s)
      // io.debug("b: " <> b)
      case
        int.parse(s),
        b |> string.pad_end(2, "0") |> string.slice(0, 2) |> int.parse
      {
        Ok(s), Ok(b) -> {
          // io.debug("s2: " <> s |> int.to_string)
          // io.debug("b2: " <> b |> int.to_string)
          Money(is_neg * { s * 100 + b })
        }
        _, _ -> Money(0)
      }
    }
    [s, ..] ->
      case int.parse(s) {
        Ok(s) -> Money(is_neg * s * 100)
        _ -> Money(0)
      }
    _ -> Money(0)
  }
}

pub fn money_to_string(m: Money) -> String {
  let sign = sign_symbols(m)
  sign <> "€" <> money_to_string_no_sign(m)
}

pub fn money_to_string_no_sign(m: Money) -> String {
  let value = m.value |> int.absolute_value
  value / 100 |> int.to_string <> "." <> value % 100 |> int.to_string
}

pub fn money_to_string_no_currency(m: Money) -> String {
  let sign = sign_symbols(m)
  let value = m.value |> int.absolute_value
  sign <> value / 100 |> int.to_string <> "." <> value % 100 |> int.to_string
}

pub fn money_with_currency_no_sign(m: Money) -> String {
  let value = m.value |> int.absolute_value
  "€" <> value / 100 |> int.to_string <> "." <> value % 100 |> int.to_string
}

fn sign_symbols(m: Money) -> String {
  case m.value < 0 {
    True -> "-"
    False -> ""
  }
}

pub fn is_zero_euro(m: Money) -> Bool {
  case m.value {
    0 -> True
    _ -> False
  }
}
// pub fn is_zero_int(m: Money) -> Bool {
//   m.s == 0
// }
