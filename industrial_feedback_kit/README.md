# industrial_feedback_kit

Phản hồi **rung + âm thanh** chuẩn nhà xưởng cho kết quả quét: PASS (rung dứt khoát + bíp), FAIL / NG (rung kép + âm cảnh báo), WARNING. Dùng âm hệ thống, không cần thư viện ngoài.

Kit **bắt buộc** trong bộ chuẩn app PDA. Tag: `industrial_feedback_kit-vX.Y.Z`. Lịch sử: [CHANGELOG.md](./CHANGELOG.md).

## 1. Khai báo

```yaml
dependencies:
  industrial_feedback_kit:
    git:
      url: https://github.com/vanvinh1204/code_design_flutter.git
      path: industrial_feedback_kit
      ref: industrial_feedback_kit-v0.1.0
```

Yêu cầu: Dart `^3.12.0`, Flutter `>=3.44.0`.

## 2. API chính

| Thành phần | Vai trò |
| :--- | :--- |
| `FeedbackType` | `success`, `error`, `warning`. |
| `IndustrialFeedback(hapticService:, audioAdapter:)` | Deep module gộp rung + âm: `notifySuccess()`, `notifyError()`, `notifyWarning()`, `trigger(type)`. Mặc định dùng `IndustrialHapticService()` + `SystemSoundAudioAdapter()`. |
| `IndustrialHapticService(enabled:)` | Rung theo loại; `enabled: false` để tắt (test, thiết bị không có motor). |
| `IndustrialAudioAdapter` | Seam phát âm thanh. Có `SystemSoundAudioAdapter(enabled:)` (âm hệ thống) và `MockAudioAdapter` (ghi `playedEvents`). |

Muốn phát file beep riêng (`assets/`), implement `IndustrialAudioAdapter` trong `adapters/` của app và truyền vào `audioAdapter:`.

## 3. Ví dụ

```dart
import 'package:industrial_feedback_kit/industrial_feedback_kit.dart';

const feedback = IndustrialFeedback();

Future<void> onScan(bool ok) async {
  if (ok) {
    await feedback.notifySuccess();
  } else {
    await feedback.notifyError();
  }
}
```

Test không cần thiết bị:

```dart
final audio = MockAudioAdapter();
final feedback = IndustrialFeedback(
  audioAdapter: audio,
  hapticService: const IndustrialHapticService(enabled: false),
);
await feedback.notifyError();
audio.playedEvents; // [FeedbackType.error]
```

## 4. Test

```bash
flutter test
```
