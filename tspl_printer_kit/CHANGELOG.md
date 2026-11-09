# Changelog

Tất cả các thay đổi đáng chú ý của package `tspl_printer_kit` được ghi chép tại tệp này.

Định dạng tuân theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/)
và quy chuẩn [Semantic Versioning](https://semver.org/lang/vi/).
Tag phát hành theo dạng `tspl_printer_kit-vX.Y.Z`.

---

## [Unreleased]

---

## [0.1.0] - 2026-11-09

### Đã thêm (Added)
- `TsplBuilder`: sinh lệnh TSPL dạng chuỗi hoặc byte (`SIZE`, `GAP`, `DIRECTION`, `REFERENCE`, `CLS`, `TEXT`, `BARCODE`, `QRCODE`, `BOX`, `BAR`, `PRINT`, lệnh thô `raw()`).
- `TsplTransport` (seam) với hai adapter: `TcpTransport` (TCP Socket, mặc định cổng 9100) và `MockTransport` (ghi lại byte đã gửi để viết test).
- `TsplPrinter`: gửi job in từ `TsplBuilder` qua transport; factory `TsplPrinter.network(ip)`.

### Đã sửa (Fixed)
- `pubspec.yaml` chỉ dùng ASCII (mô tả tiếng Anh): pub trên Windows giải mã `git show` của git dependency theo code page hệ thống, mô tả tiếng Việt làm `flutter pub get` ở app lỗi `Unexpected character`.
