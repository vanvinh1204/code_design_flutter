# Changelog

Tất cả các thay đổi đáng chú ý của package `pda_broadcast_kit` được ghi chép tại tệp này.

Định dạng tuân theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/)
và quy chuẩn [Semantic Versioning](https://semver.org/lang/vi/).
Tag phát hành theo dạng `pda_broadcast_kit-vX.Y.Z`.

---

## [Unreleased]

---

## [0.2.1] - 2026-11-09

### Đã thêm (Added)
- Plugin Android (Kotlin, đăng ký sẵn `PdaBroadcastKitPlugin`) nhận broadcast quét mã từ PDA Zebra (DataWedge) và iData, đẩy sang Flutter qua `EventChannel`.
- `PdaBroadcastController` (`ChangeNotifier`): lắng nghe `EventChannel`, lưu `lastBarcode`, `receivedCount`, `history` (cắt ở `maxHistory`), `status`; tùy chọn `MethodChannel` điều khiển DataWedge (`switchToAppProfile`, `startScan`, `enableDataWedge`, `reapplyProfile`, `getActiveProfile`, `loadDiagnostics`).
- `extractBarcodeFromEvent()`: giải mã chuỗi quét từ payload native, gộp các khóa của Zebra (`resolvedBarcode`, `com.symbol.datawedge.data_string`, `decode_data`) và iData (`value`, `barcode`, `data`, `result`).
- `PdaBroadcastChannels`: tên kênh mặc định khớp native (`zebra_tc21/broadcast_events`, `zebra_tc21/datawedge`, `idata/broadcast_events`).
- `PdaBroadcastDebugPage`: trang debug hiển thị trạng thái, mã quét khổ lớn, lịch sử và nút DataWedge.
- Bộ test Dart cho `extractBarcodeFromEvent()` và `PdaBroadcastController` (mock `EventChannel` / `MethodChannel`).
