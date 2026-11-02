// How C# NepDate's own tests are covered (shared/spec/PORT-PLAN.md, "C# test catalogue").
//
// `checkCatalog` declares one test per catalogue row of the given phase tags, named after the
// row's id. A row with no case, and a case with no row, fail with the id, so the two cannot drift.

import 'package:test/test.dart';

import 'vectors.dart';

/// One catalogue row: the C# assertions translated to this API, or a skip with the reason.
class CatalogCase {
  /// The C# assertions translated to this port's API.
  const CatalogCase(this.body) : skipReason = null;

  /// PARITY.md says the port behaves differently, so the row is skipped with that D number.
  const CatalogCase.deviation(String id)
      : body = null,
        skipReason = id;

  /// The row needs an API this port does not have; [what] names it.
  const CatalogCase.notApplicable(String what)
      : body = null,
        skipReason = 'n/a: $what';

  /// The test body, or `null` for a skipped row.
  final void Function()? body;

  /// Why the row is skipped, or `null`.
  final String? skipReason;
}

List<Row>? _catalog;

/// The catalogue rows whose `phase` column is one of [tags].
List<Row> catalogRows(Iterable<String> tags, {String? file}) {
  final all = _catalog ??= readVectors('csharp-tests/catalog.tsv');
  return [
    for (final row in all)
      if (tags.contains(row['phase']) && (file == null || row['file'] == file)) row,
  ];
}

/// Declares one test per catalogue row of [tags] (restricted to [file] when given), named after the
/// row's id.
void checkCatalog(List<String> tags, Map<String, CatalogCase> cases, {String? file}) {
  final ids = <String>{for (final row in catalogRows(tags, file: file)) row['id']};
  for (final id in ids) {
    final entry = cases[id];
    if (entry == null) {
      test(id, () => fail('catalogue row $id has no case'));
    } else if (entry.body != null) {
      test(id, entry.body!);
    } else {
      test(id, () {}, skip: entry.skipReason);
    }
  }
  for (final id in cases.keys) {
    if (!ids.contains(id)) {
      test('stale case $id', () => fail('case $id matches no catalogue row tagged $tags'));
    }
  }
}
