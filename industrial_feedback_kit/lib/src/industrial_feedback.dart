import 'audio_service.dart';
import 'feedback_type.dart';
import 'haptic_service.dart';

/// Bộ điều khiển phản hồi tổng hợp (Deep Module) kết hợp âm thanh & rung
class IndustrialFeedback {
  final IndustrialHapticService hapticService;
  final IndustrialAudioAdapter audioAdapter;

  const IndustrialFeedback({
    this.hapticService = const IndustrialHapticService(),
    this.audioAdapter = const SystemSoundAudioAdapter(),
  });

  /// Báo hiệu quét thành công (PASS): rung dứt khoát + tiếng bíp ngắn
  Future<void> notifySuccess() async {
    await Future.wait([
      hapticService.trigger(FeedbackType.success),
      audioAdapter.play(FeedbackType.success),
    ]);
  }

  /// Báo hiệu quét lỗi / sai mã (NG): rung cảnh báo liên hồi + âm thanh cảnh báo
  Future<void> notifyError() async {
    await Future.wait([
      hapticService.trigger(FeedbackType.error),
      audioAdapter.play(FeedbackType.error),
    ]);
  }

  /// Báo hiệu cảnh báo (WARNING)
  Future<void> notifyWarning() async {
    await Future.wait([
      hapticService.trigger(FeedbackType.warning),
      audioAdapter.play(FeedbackType.warning),
    ]);
  }

  /// Kích hoạt theo loại tùy biến
  Future<void> trigger(FeedbackType type) async {
    switch (type) {
      case FeedbackType.success:
        return notifySuccess();
      case FeedbackType.error:
        return notifyError();
      case FeedbackType.warning:
        return notifyWarning();
    }
  }
}
