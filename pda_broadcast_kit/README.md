# pda_broadcast_kit

Plugin Android (Kotlin đăng ký sẵn, không cần chép native vào app) nhận broadcast quét mã từ PDA **Zebra (DataWedge)** và **iData**, đẩy sang Flutter qua `EventChannel`; tùy chọn điều khiển DataWedge qua `MethodChannel`.

Kit **bắt buộc** trong bộ chuẩn app PDA. Tag: `pda_broadcast_kit-vX.Y.Z`. Lịch sử: [CHANGELOG.md](./CHANGELOG.md).

## 1. Khai báo

```yaml
dependencies:
  pda_broadcast_kit:
    git:
      url: https://github.com/vanvinh1204/code_design_flutter.git
      path: pda_broadcast_kit
      ref: pda_broadcast_kit-v0.2.1
```

Yêu cầu: Dart `^3.12.0`, Flutter `>=3.44.0`, Android.

## 2. API chính

| Thành phần | Vai trò |
| :--- | :--- |
| `PdaBroadcastController` | `ChangeNotifier` lắng nghe `EventChannel`; giữ `lastBarcode`, `receivedCount`, `history` (cắt ở `maxHistory`, mặc định 50), `status`, `diagnostics`. |
| `PdaBroadcastChannels` | Tên kênh mặc định khớp native: `zebraTc21Broadcast`, `zebraTc21DataWedge`, `idataBroadcast`. |
| `extractBarcodeFromEvent(Map)` | Hàm Dart thuần trích chuỗi quét từ payload native (Zebra `resolvedBarcode` / `data_string` / `decode_data`, iData `value` / `barcode` / `data` / `result`). Trả `''` nếu không có mã. |
| `PdaBroadcastDebugPage` | Trang debug: trạng thái, mã quét khổ lớn, lịch sử, nút DataWedge. |

Phương thức DataWedge (chỉ khi truyền `methodChannelName`): `switchToAppProfile()`, `startScan()`, `enableDataWedge()`, `reapplyProfile()`, `getActiveProfile()`, `loadDiagnostics()`. Lỗi native không ném ra ngoài mà ghi vào `status`.

## 3. Ví dụ

```dart
import 'package:pda_broadcast_kit/pda_broadcast_kit.dart';

final pda = PdaBroadcastController(
  eventChannelName: PdaBroadcastChannels.zebraTc21Broadcast,
  methodChannelName: PdaBroadcastChannels.zebraTc21DataWedge, // bỏ với iData
);

int seen = 0;
pda.addListener(() {
  if (pda.receivedCount == seen) return; // chỉ xử lý khi có lần quét mới
  seen = pda.receivedCount;
  if (pda.lastBarcode.isNotEmpty) handleBarcode(pda.lastBarcode);
});
pda.startListening();

// ... khi không dùng nữa
pda.dispose();
```

Trang debug nhanh khi thử máy mới:

```dart
PdaBroadcastDebugPage(
  controller: pda,
  title: 'Thử PDA',
  showDataWedgeControls: true, // Zebra
)
```

## 4. Test

```bash
flutter test
```

Phần giải mã (`extractBarcodeFromEvent`) test thuần Dart; `EventChannel` / `MethodChannel` được mock bằng `TestDefaultBinaryMessengerBinding`.
