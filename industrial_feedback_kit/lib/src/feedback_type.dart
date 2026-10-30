/// Kiểu phản hồi công nghiệp
enum FeedbackType {
  /// Quét thành công, dữ liệu hợp lệ (PASS)
  success,

  /// Quét lỗi, sai mã, hoặc dữ liệu không hợp lệ (NG / FAIL)
  error,

  /// Cảnh báo, cần người dùng chú ý (WARNING)
  warning,
}
