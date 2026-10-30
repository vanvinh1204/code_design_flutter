import 'package:flutter/services.dart';
import 'feedback_type.dart';

/// Dịch vụ rung (Haptic Feedback) tối ưu cho thao tác quét công nghiệp
class IndustrialHapticService {
  final bool enabled;

  const IndustrialHapticService({this.enabled = true});

  /// Kích hoạt rung tương ứng với loại phản hồi
  Future<void> trigger(FeedbackType type) async {
    if (!enabled) return;

    try {
      switch (type) {
        case FeedbackType.success:
          // Rung ngắn, dứt khoát xác nhận PASS
          await HapticFeedback.mediumImpact();
          break;
        case FeedbackType.error:
          // Rung mạnh liên hoàn cảnh báo NG
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.heavyImpact();
          break;
        case FeedbackType.warning:
          await HapticFeedback.selectionClick();
          break;
      }
    } catch (_) {
      // Bỏ qua lỗi nếu thiết bị không hỗ trợ rung phần cứng
    }
  }
}
