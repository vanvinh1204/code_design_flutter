/// Kết quả phân tích chuỗi mã vạch
class ParsedBarcode {
  /// Chuỗi gốc sau khi làm sạch
  final String rawText;

  /// Các phần tử sau khi cắt (nếu có ký tự phân cách)
  final List<String> segments;

  /// Các trường dữ liệu đã được gán nhãn theo schema
  final Map<String, String> fields;

  /// Định danh schema hoặc loại mã vạch nhận diện được
  final String? formatId;

  const ParsedBarcode({
    required this.rawText,
    this.segments = const [],
    this.fields = const {},
    this.formatId,
  });

  /// Lấy giá trị của một trường, trả về rỗng nếu không có
  String get(String key) => fields[key] ?? '';

  /// Kiểm tra có trường dữ liệu này không
  bool has(String key) => fields.containsKey(key) && fields[key]!.isNotEmpty;

  @override
  String toString() =>
      'ParsedBarcode(formatId: $formatId, fields: $fields, raw: $rawText)';
}
