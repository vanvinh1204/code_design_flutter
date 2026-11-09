# tspl_printer_kit

Package **Dart thuần** sinh lệnh in tem nhãn **TSPL** (TSC, Xprinter, Gprinter) và gửi tới máy in qua TCP Socket (cổng 9100) hoặc transport tùy biến.

Kit **tùy chọn**: chỉ khai báo khi app có in tem nhãn. Tag: `tspl_printer_kit-vX.Y.Z`. Lịch sử: [CHANGELOG.md](./CHANGELOG.md).

## 1. Khai báo

```yaml
dependencies:
  tspl_printer_kit:
    git:
      url: https://github.com/vanvinh1204/code_design_flutter.git
      path: tspl_printer_kit
      ref: tspl_printer_kit-v0.1.0
```

Yêu cầu: Dart `^3.12.0`, có `dart:io` (không chạy trên web).

## 2. API chính

| Thành phần | Vai trò |
| :--- | :--- |
| `TsplBuilder` | Sinh lệnh theo kiểu chuỗi gọi: `size()`, `gap()`, `direction()`, `reference()`, `cls()`, `text()`, `barcode()`, `qrcode()`, `box()`, `bar()`, `print()`, `raw()`. Xuất bằng `buildString()` / `buildBytes(encoding:)`; `reset()` để làm tem mới. |
| `TsplTransport` | Seam kênh truyền: `connect()`, `send(bytes)`, `disconnect()`, `isConnected`. |
| `TcpTransport(host:, port: 9100, timeout:)` | Gửi qua LAN / Wi-Fi. |
| `MockTransport` | Ghi lại `sentBytes` để viết test hoặc chạy thử không có máy in. |
| `TsplPrinter(transport:, encoding:)` | Gửi job từ `TsplBuilder`; factory `TsplPrinter.network(ip)`. `printJob()` tự `connect()` nếu chưa kết nối (với `TcpTransport`). |

Đơn vị tọa độ trong `text()`, `barcode()`, `qrcode()`, `box()`, `bar()` là **dot** (203 dpi ≈ 8 dot/mm). `size()` và `gap()` tính theo **mm**.

## 3. Ví dụ

```dart
import 'package:tspl_printer_kit/tspl_printer_kit.dart';

final job = TsplBuilder()
    .size(widthMm: 60, heightMm: 40)
    .gap(gapMm: 2)
    .direction(1)
    .cls()
    .text(x: 20, y: 20, text: 'PART: 82824-B1010', font: '3')
    .barcode(x: 20, y: 70, content: '82824-B1010', height: 60)
    .qrcode(x: 320, y: 60, content: '82824-B1010|50', cellWidth: 5)
    .print(count: 2);

final printer = TsplPrinter.network('192.168.1.100');
try {
  await printer.printJob(job);
} finally {
  await printer.disconnect();
}
```

Test với transport giả:

```dart
final mock = MockTransport();
final printer = TsplPrinter(transport: mock);
await printer.connect();
await printer.printJob(TsplBuilder().size(widthMm: 50, heightMm: 30).print());
utf8.decode(mock.sentBytes.single); // chứa 'PRINT 1,1'
```

## 4. Test

```bash
flutter test   # hoặc: dart test
```
