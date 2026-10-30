import 'package:flutter/services.dart';
import 'feedback_type.dart';

/// Ranh giới (Seam) cho tầng phát âm thanh
abstract interface class IndustrialAudioAdapter {
  Future<void> play(FeedbackType type);
}

/// Adapter phát âm thanh qua hệ thống mặc định của hệ điều hành (không cần thêm thư viện ngoài)
class SystemSoundAudioAdapter implements IndustrialAudioAdapter {
  final bool enabled;

  const SystemSoundAudioAdapter({this.enabled = true});

  @override
  Future<void> play(FeedbackType type) async {
    if (!enabled) return;

    try {
      switch (type) {
        case FeedbackType.success:
          await SystemSound.play(SystemSoundType.click);
          break;
        case FeedbackType.error:
        case FeedbackType.warning:
          await SystemSound.play(SystemSoundType.alert);
          break;
      }
    } catch (_) {
      // Bỏ qua nếu nền tảng không hỗ trợ
    }
  }
}

/// Adapter giả lập phục vụ kiểm thử
class MockAudioAdapter implements IndustrialAudioAdapter {
  final List<FeedbackType> playedEvents = [];

  @override
  Future<void> play(FeedbackType type) async {
    playedEvents.add(type);
  }

  void clear() => playedEvents.clear();
}
