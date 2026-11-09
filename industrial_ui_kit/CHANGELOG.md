# Changelog

Tất cả các thay đổi đáng chú ý của package `industrial_ui_kit` được ghi chép tại tệp này.

Định dạng tuân theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/)
và quy chuẩn [Semantic Versioning](https://semver.org/lang/vi/).
Tag phát hành theo dạng `industrial_ui_kit-vX.Y.Z`.

---

## [Unreleased]

---

## [0.1.0] - 2026-11-09

### Đã thêm (Added)
- `ScanFocusKeeper`: giữ tiêu điểm cho ô nhận dữ liệu scanner HID / PDA, tự đòi lại focus sau khi chạm màn hình, đóng popup hoặc app quay lại foreground; tạm dừng bằng `isPaused`.
- `IndustrialStatusBanner` + `IndustrialStatus` (`idle`, `processing`, `pass`, `fail`): bảng trạng thái khổ lớn, tương phản cao.
- `ScanFlashOverlay` + `ScanFlashController`: chớp màu toàn màn hình xanh (PASS) / đỏ (FAIL).

### Đã sửa (Fixed)
- `pubspec.yaml` chỉ dùng ASCII (mô tả tiếng Anh): pub trên Windows giải mã `git show` của git dependency theo code page hệ thống, mô tả tiếng Việt làm `flutter pub get` ở app lỗi `Unexpected character`.
