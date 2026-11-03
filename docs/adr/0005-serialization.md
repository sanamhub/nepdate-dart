# 0005: `toJson` and `fromJson` as the only serialization hook

Status: accepted.

## Context

C# NepDate offers four serialization adapters, an XML serializer, a `TypeConverter` and a
`YYYYMMDD` integer. Each has its own shape, and two of them write an object instead of a string.
The Dart ecosystem serializes through `jsonEncode`, which calls `toJson`, and deserializes through
a factory or a static method the caller names.

## Decision

- A date writes `YYYY-MM-DD` from `toJson()`, which returns a `String`, so `jsonEncode` produces a
  JSON string.
- `NepaliDate.fromJson(Object? json)` accepts that string and nothing else. A map, a number or
  `null` throws `NepDateException` with `unrecognized`.
- The `YYYYMMDD` integer remains a separate pair, `fromYmd` and `ymd` (`D-11`).
- There is no object form, no XML adapter, no `TypeConverter` class and no separate codec
  package. A caller who needs another shape maps the three fields itself.
- The attribute names of the object form in C# are not reproduced anywhere.

## Consequences

One text form crosses a language boundary, and it is the same one every port uses. A JSON round trip
is a string in and a string out, with no custom `JsonConverter` to register. The object form and the
integer form cannot be confused with a date value.
