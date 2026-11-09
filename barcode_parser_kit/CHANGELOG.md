# Changelog

Tất cả các thay đổi đáng chú ý của package `barcode_parser_kit` được ghi chép tại tệp này.

Định dạng tuân theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/)
và quy chuẩn [Semantic Versioning](https://semver.org/lang/vi/).
Tag phát hành theo dạng `barcode_parser_kit-vX.Y.Z`.

---

## [Unreleased]

---

## [0.1.0] - 2026-11-09

### Đã thêm (Added)
- `BarcodeCleaner.clean()`: loại bỏ ký tự điều khiển (STX, ETX, CR, LF, NUL, ...) và khoảng trắng hai đầu chuỗi quét thô.
- `BarcodeCleaner.stripSurround()`: bỏ tiền tố / hậu tố do scanner tự thêm.
- `DelimiterSchema`: định nghĩa cách bóc tách theo ký tự phân cách và danh sách tên trường (`fieldKeys`, `minSegments`).
- `BarcodeParser`: thử lần lượt các schema, rơi về `defaultDelimiter`, cuối cùng trả chuỗi đơn.
- `ParsedBarcode`: kết quả có `rawText`, `segments`, `fields`, `formatId`, kèm `get()` / `has()`.

### Đã sửa (Fixed)
- `pubspec.yaml` chỉ dùng ASCII (mô tả tiếng Anh): pub trên Windows giải mã `git show` của git dependency theo code page hệ thống, mô tả tiếng Việt làm `flutter pub get` ở app lỗi `Unexpected character`.
