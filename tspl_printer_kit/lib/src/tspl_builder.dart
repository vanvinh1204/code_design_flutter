import 'dart:convert';

/// Trình xây dựng chuỗi lệnh TSPL (TSC Printer Language) cho máy in tem nhãn.
class TsplBuilder {
  final StringBuffer _buffer = StringBuffer();

  /// Đặt kích thước nhãn (đơn vị: mm)
  TsplBuilder size({required double widthMm, required double heightMm}) {
    _buffer.writeln('SIZE $widthMm mm, $heightMm mm');
    return this;
  }

  /// Đặt khoảng cách giữa 2 con tem (Gap)
  TsplBuilder gap({required double gapMm, double offsetMm = 0}) {
    _buffer.writeln('GAP $gapMm mm, $offsetMm mm');
    return this;
  }

  /// Hướng in (0 hoặc 1)
  TsplBuilder direction(int direction) {
    _buffer.writeln('DIRECTION $direction');
    return this;
  }

  /// Tọa độ gốc tham chiếu (x, y tính theo dot)
  TsplBuilder reference(int x, int y) {
    _buffer.writeln('REFERENCE $x,$y');
    return this;
  }

  /// Xóa bộ đệm hình ảnh của máy in trước khi vẽ nhãn mới
  TsplBuilder cls() {
    _buffer.writeln('CLS');
    return this;
  }

  /// In văn bản (Text)
  /// [font]: Thường là "1", "2", "3", "4", "5" hoặc font tiếng Việt/TrueType "TSS24.BF2"
  TsplBuilder text({
    required int x,
    required int y,
    required String text,
    String font = '3',
    int rotation = 0,
    int xMul = 1,
    int yMul = 1,
  }) {
    // Thoát ký tự quote nếu có
    final escaped = text.replaceAll('"', r'\"');
    _buffer.writeln('TEXT $x,$y,"$font",$rotation,$xMul,$yMul,"$escaped"');
    return this;
  }

  /// In mã vạch 1D (Code 128, Code 39, EAN13...)
  /// [humanReadable]: 0 (không hiện số), 1 (căn trái), 2 (căn giữa), 3 (căn phải)
  TsplBuilder barcode({
    required int x,
    required int y,
    required String content,
    String type = '128',
    int height = 50,
    int humanReadable = 1,
    int rotation = 0,
    int narrow = 2,
    int wide = 4,
  }) {
    _buffer.writeln(
      'BARCODE $x,$y,"$type",$height,$humanReadable,$rotation,$narrow,$wide,"$content"',
    );
    return this;
  }

  /// In mã hai chiều QR Code
  /// [eccLevel]: L (7%), M (15%), Q (25%), H (30%)
  /// [cellWidth]: Kích thước mỗi cell chấm vuông (1 - 10)
  TsplBuilder qrcode({
    required int x,
    required int y,
    required String content,
    String eccLevel = 'M',
    int cellWidth = 4,
    int rotation = 0,
  }) {
    _buffer.writeln('QRCODE $x,$y,$eccLevel,$cellWidth,A,$rotation,"$content"');
    return this;
  }

  /// Vẽ đường viền khung hình chữ nhật
  TsplBuilder box({
    required int x,
    required int y,
    required int xEnd,
    required int yEnd,
    int lineThickness = 2,
  }) {
    _buffer.writeln('BOX $x,$y,$xEnd,$yEnd,$lineThickness');
    return this;
  }

  /// Vẽ vạch kẻ (đường thẳng ngang hoặc dọc)
  TsplBuilder bar({
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    _buffer.writeln('BAR $x,$y,$width,$height');
    return this;
  }

  /// Lệnh xuất in ra nhãn
  /// [count]: Số lượng con tem cần in
  /// [copies]: Số bản in nhân bản cho mỗi tem
  TsplBuilder print({int count = 1, int copies = 1}) {
    _buffer.writeln('PRINT $count,$copies');
    return this;
  }

  /// Thêm lệnh TSPL thô tùy biến
  TsplBuilder raw(String command) {
    _buffer.writeln(command);
    return this;
  }

  /// Lấy toàn bộ lệnh dưới dạng String
  String buildString() => _buffer.toString();

  /// Chuyển đổi lệnh thành chuỗi byte (mặc định Latin1/ASCII hoặc UTF-8)
  List<int> buildBytes({Encoding encoding = utf8}) {
    return encoding.encode(buildString());
  }

  /// Xóa nội dung builder để tạo nhãn mới
  void reset() {
    _buffer.clear();
  }
}
