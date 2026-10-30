import 'cleaner.dart';
import 'parsed_barcode.dart';

/// Định nghĩa một schema để bóc tách mã vạch dựa trên vị trí các phần tử phân cách
class DelimiterSchema {
  final String id;
  final String delimiter;

  /// Danh sách tên các trường tương ứng với từng chỉ số index sau khi split
  /// Ví dụ: ['partNo', 'qty', 'lotNo', 'date']
  final List<String> fieldKeys;

  final int? _minSegments;

  const DelimiterSchema({
    required this.id,
    required this.delimiter,
    required this.fieldKeys,
    int? minSegments,
  }) : _minSegments = minSegments;

  int get minSegments => _minSegments ?? fieldKeys.length;

  bool matches(List<String> segments) {
    return segments.length >= minSegments;
  }

  ParsedBarcode parse(String rawText, List<String> segments) {
    final fields = <String, String>{};
    for (var i = 0; i < fieldKeys.length && i < segments.length; i++) {
      fields[fieldKeys[i]] = segments[i].trim();
    }
    return ParsedBarcode(
      rawText: rawText,
      segments: segments,
      fields: fields,
      formatId: id,
    );
  }
}

/// Bộ phân tích mã vạch dựa trên bộ quy tắc (Schemas)
class BarcodeParser {
  final List<DelimiterSchema> schemas;
  final String? defaultDelimiter;

  const BarcodeParser({
    this.schemas = const [],
    this.defaultDelimiter,
  });

  /// Phân tích một chuỗi mã vạch
  ParsedBarcode parse(String raw) {
    final cleaned = BarcodeCleaner.clean(raw);
    if (cleaned.isEmpty) {
      return const ParsedBarcode(rawText: '');
    }

    // 1. Thử khớp với từng schema đã đăng ký
    for (final schema in schemas) {
      if (cleaned.contains(schema.delimiter)) {
        final segments = cleaned.split(schema.delimiter);
        if (schema.matches(segments)) {
          return schema.parse(cleaned, segments);
        }
      }
    }

    // 2. Nếu không khớp schema nào nhưng có defaultDelimiter
    if (defaultDelimiter != null && cleaned.contains(defaultDelimiter!)) {
      final segments = cleaned.split(defaultDelimiter!);
      return ParsedBarcode(
        rawText: cleaned,
        segments: segments,
      );
    }

    // 3. Chuỗi đơn lẻ không có phân cách
    return ParsedBarcode(rawText: cleaned);
  }
}
