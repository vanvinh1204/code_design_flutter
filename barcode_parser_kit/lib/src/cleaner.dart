/// Tiện ích làm sạch chuỗi mã vạch thô nhận được từ scanner PDA/Wedge.
class BarcodeCleaner {
  const BarcodeCleaner._();

  /// Loại bỏ các ký tự điều khiển phổ biến như STX (0x02), ETX (0x03), CR (\r), LF (\n),
  /// null bytes và khoảng trắng thừa ở 2 đầu.
  static String clean(String raw) {
    if (raw.isEmpty) return '';

    return raw
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        .trim();
  }

  /// Loại bỏ tiền tố (prefix) và hậu tố (suffix) nếu scanner tự cấu hình thêm vào.
  static String stripSurround(String raw, {String? prefix, String? suffix}) {
    var result = clean(raw);
    if (prefix != null && prefix.isNotEmpty && result.startsWith(prefix)) {
      result = result.substring(prefix.length);
    }
    if (suffix != null && suffix.isNotEmpty && result.endsWith(suffix)) {
      result = result.substring(0, result.length - suffix.length);
    }
    return result.trim();
  }
}
