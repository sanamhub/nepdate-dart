// Readers for the shared vector files in shared/spec/vectors (spec/README.md "vector formats").

import 'dart:convert';
import 'dart:io';

/// The hub's counts for the vendored patro data (shared/spec/vectors/patro-summary.json).
Map<String, Object?> readPatroSummary() {
  final file = File('${repositoryRoot().path}/shared/spec/vectors/patro-summary.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

/// The repository root: the first parent of the working directory that holds `shared/`.
Directory repositoryRoot() {
  var dir = Directory.current.absolute;
  while (!Directory('${dir.path}${Platform.pathSeparator}shared').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('no shared/ directory above ${Directory.current.path}');
    }
    dir = parent;
  }
  return dir;
}

/// One data row of a vector file, by column name.
class Row {
  Row(this._columns, this._values, this.line);

  final List<String> _columns;
  final List<String> _values;

  /// 1-based line number in the file, for failure messages.
  final int line;

  String operator [](String column) {
    final index = _columns.indexOf(column);
    if (index < 0) throw ArgumentError('no column $column in $_columns');
    return index < _values.length ? _values[index] : '';
  }

  @override
  String toString() => 'line $line: ${_values.join(' | ')}';
}

/// Reads a tab-separated vector file. Blank lines and lines that start with `#` are skipped, the
/// first remaining line is the header, and quotes are ordinary characters (serialization.tsv holds
/// literal JSON). A `.csv` file is split on commas instead.
List<Row> readVectors(String relative) {
  final file = File('${repositoryRoot().path}/shared/spec/vectors/$relative');
  final delimiter = relative.endsWith('.csv') ? ',' : '\t';
  final rows = <Row>[];
  List<String>? header;
  var number = 0;
  for (final line in file.readAsLinesSync()) {
    number++;
    if (line.isEmpty || line.startsWith('#')) continue;
    final fields = line.split(delimiter);
    if (header == null) {
      header = fields;
    } else {
      rows.add(Row(header, fields, number));
    }
  }
  return rows;
}
