import 'dart:convert';
import 'dart:io';

/// Helper to load and decode a JSON fixture file from `test/fixtures/`.
Map<String, dynamic> jsonFixture(String fileName) {
  final file = File('test/fixtures/$fileName');
  final content = file.readAsStringSync();
  final dynamic decoded = jsonDecode(content);
  return Map<String, dynamic>.from(decoded as Map);
}
