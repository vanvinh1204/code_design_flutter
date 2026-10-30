import 'package:barcode_parser_kit/barcode_parser_kit.dart';
import 'package:test/test.dart';

void main() {
  group('BarcodeCleaner', () {
    test('cleans carriage return, newlines, control characters', () {
      const raw = '\x02PART-1234\r\n\x03';
      expect(BarcodeCleaner.clean(raw), equals('PART-1234'));
    });

    test('strips prefix and suffix correctly', () {
      const raw = 'SCAN:XYZ-999-END';
      final cleaned = BarcodeCleaner.stripSurround(raw, prefix: 'SCAN:', suffix: '-END');
      expect(cleaned, equals('XYZ-999'));
    });
  });

  group('BarcodeParser with DelimiterSchema', () {
    final parser = BarcodeParser(
      schemas: [
        const DelimiterSchema(
          id: 'kanban_pipe',
          delimiter: '|',
          fieldKeys: ['partNo', 'qty', 'lot', 'date'],
        ),
      ],
      defaultDelimiter: ';',
    );

    test('parses matched schema into structured fields', () {
      const raw = 'ABC-001|50|LOT20261014|2026-10-14\r\n';
      final result = parser.parse(raw);

      expect(result.formatId, equals('kanban_pipe'));
      expect(result.get('partNo'), equals('ABC-001'));
      expect(result.get('qty'), equals('50'));
      expect(result.get('lot'), equals('LOT20261014'));
      expect(result.get('date'), equals('2026-10-14'));
      expect(result.has('partNo'), isTrue);
      expect(result.has('nonExisting'), isFalse);
    });

    test('falls back to defaultDelimiter if no schema matches', () {
      const raw = 'A;B;C';
      final result = parser.parse(raw);
      expect(result.formatId, isNull);
      expect(result.segments, equals(['A', 'B', 'C']));
    });

    test('returns raw string when no delimiter matches', () {
      const raw = 'SINGLE_CODE';
      final result = parser.parse(raw);
      expect(result.rawText, equals('SINGLE_CODE'));
      expect(result.segments, isEmpty);
    });
  });
}
