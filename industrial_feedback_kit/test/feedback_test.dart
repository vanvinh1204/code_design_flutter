import 'package:flutter_test/flutter_test.dart';
import 'package:industrial_feedback_kit/industrial_feedback_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IndustrialFeedback with MockAudioAdapter', () {
    test('triggers success events correctly', () async {
      final mockAudio = MockAudioAdapter();
      final feedback = IndustrialFeedback(
        audioAdapter: mockAudio,
        hapticService: const IndustrialHapticService(enabled: false),
      );

      await feedback.notifySuccess();

      expect(mockAudio.playedEvents, equals([FeedbackType.success]));
    });

    test('triggers error events correctly', () async {
      final mockAudio = MockAudioAdapter();
      final feedback = IndustrialFeedback(
        audioAdapter: mockAudio,
        hapticService: const IndustrialHapticService(enabled: false),
      );

      await feedback.notifyError();

      expect(mockAudio.playedEvents, equals([FeedbackType.error]));
    });

    test('triggers warning events via trigger()', () async {
      final mockAudio = MockAudioAdapter();
      final feedback = IndustrialFeedback(
        audioAdapter: mockAudio,
        hapticService: const IndustrialHapticService(enabled: false),
      );

      await feedback.trigger(FeedbackType.warning);

      expect(mockAudio.playedEvents, equals([FeedbackType.warning]));
    });
  });
}
