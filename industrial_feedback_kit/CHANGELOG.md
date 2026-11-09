# Changelog

Tất cả các thay đổi đáng chú ý của package `industrial_feedback_kit` được ghi chép tại tệp này.

Định dạng tuân theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/)
và quy chuẩn [Semantic Versioning](https://semver.org/lang/vi/).
Tag phát hành theo dạng `industrial_feedback_kit-vX.Y.Z`.

---

## [Unreleased]

---

## [0.1.0] - 2026-11-09

### Đã thêm (Added)
- `FeedbackType` (`success`, `error`, `warning`).
- `IndustrialHapticService`: rung theo loại phản hồi (PASS rung dứt khoát, NG rung kép), tắt được bằng `enabled: false`.
- `IndustrialAudioAdapter` (seam) với `SystemSoundAudioAdapter` (âm hệ thống, không cần thư viện ngoài) và `MockAudioAdapter` (ghi lại sự kiện để test).
- `IndustrialFeedback`: gộp rung + âm thanh qua `notifySuccess()`, `notifyError()`, `notifyWarning()`, `trigger(type)`.

### Đã sửa (Fixed)
- `pubspec.yaml` chỉ dùng ASCII (mô tả tiếng Anh): pub trên Windows giải mã `git show` của git dependency theo code page hệ thống, mô tả tiếng Việt làm `flutter pub get` ở app lỗi `Unexpected character`.
