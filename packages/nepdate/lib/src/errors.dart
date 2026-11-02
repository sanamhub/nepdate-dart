part of '../nepdate.dart';

/// What went wrong, for code that handles a [NepDateException].
///
/// ```dart
/// try {
///   NepaliDate.fromBs(2081, 13, 1);
/// } on NepDateException catch (error) {
///   error.kind; // => ErrorKind.invalidMonth
/// }
/// ```
enum ErrorKind {
  /// The date is outside BS 1901-01-01 to 2199-12-30 (AD 1844-04-11 to 2143-04-15), or a range
  /// would end before it starts.
  outOfRange,

  /// The month is not 1 to 12.
  invalidMonth,

  /// The day is not 1 to the length of the month.
  invalidDay,

  /// The text has a character that is neither a digit nor a separator.
  invalidCharacter,

  /// The text does not have exactly three groups of digits.
  wrongGroupCount,

  /// A number in the text has more than four digits.
  numberTooLong,

  /// The order of year, month and day cannot be decided.
  ambiguous,

  /// No accepted form matches the text.
  unrecognized,
}

/// The one exception type of `nepdate`: a date that is not in the calendar, or a text that is not a
/// date. [kind] says which check failed.
///
/// A bad argument that has nothing to do with the calendar, such as an interval below 1, throws an
/// [ArgumentError] instead.
///
/// ```dart
/// const error = NepDateException(ErrorKind.invalidDay, 'day 33 does not exist');
/// error.kind; // => ErrorKind.invalidDay
/// ```
final class NepDateException implements Exception {
  /// Creates an exception of [kind] with a human-readable [message].
  const NepDateException(this.kind, this.message);

  /// Which check failed.
  final ErrorKind kind;

  /// A human-readable description of the failure.
  final String message;

  @override
  String toString() => 'NepDateException(${kind.name}): $message';
}
