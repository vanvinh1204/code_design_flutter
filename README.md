# Hệ Thống Module Dùng Chung Cho Flutter (Industrial & PDA Ecosystem)

Kho lưu trữ các module độc lập, chuẩn kiến trúc **Deep Module**, chuyên dùng cho các dự án ứng dụng Flutter trong môi trường nhà máy, kho vận, thiết bị PDA và in ấn tem nhãn.

---

## 📦 Danh Sách Các Module

| Module | Đường dẫn | Loại | Mô tả chức năng |
| :--- | :--- | :--- | :--- |
| **[pda_broadcast_kit](file:///d:/project/code_design_flutter/pda_broadcast_kit)** | `./pda_broadcast_kit` | Plugin Android | Lắng nghe Broadcast PDA (Zebra TC21, iData, Honeywell) qua EventChannel, điều khiển DataWedge. |
| **[barcode_parser_kit](file:///d:/project/code_design_flutter/barcode_parser_kit)** | `./barcode_parser_kit` | Pure Dart | Làm sạch ký tự điều khiển (`\r`, `\n`, STX, ETX) và bóc tách chuỗi mã vạch / QR phân cách theo schema (`\|`, `@`, `,`). |
| **[tspl_printer_kit](file:///d:/project/code_design_flutter/tspl_printer_kit)** | `./tspl_printer_kit` | Pure Dart | Sinh lệnh in tem nhãn TSPL (Text, Barcode 1D, QR Code, Box, Line) và gửi qua mạng LAN Socket (Port 9100). |
| **[industrial_feedback_kit](file:///d:/project/code_design_flutter/industrial_feedback_kit)** | `./industrial_feedback_kit` | Flutter Package | Phản hồi xúc giác & thính giác: Rung dứt khoát / liên hồi và âm thanh Beep PASS/FAIL chuẩn nhà xưởng. |
| **[industrial_ui_kit](file:///d:/project/code_design_flutter/industrial_ui_kit)** | `./industrial_ui_kit` | Flutter Package | Giao diện công nghiệp: `ScanFocusKeeper` (chống mất con trỏ quét), `IndustrialStatusBanner` (PASS/FAIL khổ lớn), `ScanFlashOverlay` (chớp màn hình). |

---

## 🚀 Cách Khai Báo Trong Dự Án (pubspec.yaml)

Tại dự án Flutter của bạn (ví dụ `scan_shanai`, `remake_scan_yev`, `print_nameplate`):

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 1. Thu nhận mã vạch từ PDA phần cứng
  pda_broadcast_kit:
    path: ../code_design_flutter/pda_broadcast_kit

  # 2. Bóc tách dữ liệu mã vạch
  barcode_parser_kit:
    path: ../code_design_flutter/barcode_parser_kit

  # 3. Phản hồi âm thanh / rung
  industrial_feedback_kit:
    path: ../code_design_flutter/industrial_feedback_kit

  # 4. Giao diện chuyên dụng
  industrial_ui_kit:
    path: ../code_design_flutter/industrial_ui_kit

  # 5. In tem nhãn TSPL (nếu có in ấn)
  tspl_printer_kit:
    path: ../code_design_flutter/tspl_printer_kit
```

---

## 💡 Ví Dụ Kết Hợp Trọn Vẹn Quy Trình (Workflow)

```dart
import 'package:flutter/material.dart';
import 'package:pda_broadcast_kit/pda_broadcast_kit.dart';
import 'package:barcode_parser_kit/barcode_parser_kit.dart';
import 'package:industrial_feedback_kit/industrial_feedback_kit.dart';
import 'package:industrial_ui_kit/industrial_ui_kit.dart';
import 'package:tspl_printer_kit/tspl_printer_kit.dart';

void main() => runApp(const MaterialApp(home: FactoryScanScreen()));

class FactoryScanScreen extends StatefulWidget {
  const FactoryScanScreen({super.key});

  @override
  State<FactoryScanScreen> createState() => _FactoryScanScreenState();
}

class _FactoryScanScreenState extends State<FactoryScanScreen> {
  final _pdaController = PdaBroadcastController();
  final _feedback = const IndustrialFeedback();
  final _flashController = ScanFlashController();
  
  final _parser = const BarcodeParser(
    schemas: [
      DelimiterSchema(
        id: 'kanban',
        delimiter: '|',
        fieldKeys: ['partNo', 'qty', 'lotNo'],
      ),
    ],
  );

  IndustrialStatus _status = IndustrialStatus.idle;
  String _message = 'SẴN SÀNG QUÉT';

  @override
  void initState() {
    super.initState();
    _pdaController.startListening();
    _pdaController.barcodeStream.listen(_onBarcodeReceived);
  }

  Future<void> _onBarcodeReceived(String raw) async {
    final parsed = _parser.parse(raw);

    if (parsed.has('partNo')) {
      // 1. Quét thành công: Phát rung + Beep PASS + Chớp xanh toàn màn hình
      setState(() {
        _status = IndustrialStatus.pass;
        _message = '${parsed.get('partNo')} (SL: ${parsed.get('qty')})';
      });
      _feedback.notifySuccess();
      _flashController.flashSuccess();

      // 2. Tùy chọn in tem nhãn qua mạng LAN
      // await _printLabel(parsed.get('partNo'), parsed.get('qty'));
    } else {
      // Quét lỗi: Rung kép + Beep NG + Chớp đỏ
      setState(() {
        _status = IndustrialStatus.fail;
        _message = 'Mã không đúng định dạng';
      });
      _feedback.notifyError();
      _flashController.flashError();
    }
  }

  Future<void> _printLabel(String partNo, String qty) async {
    final printer = TsplPrinter.network('192.168.1.100');
    final job = TsplBuilder()
        .size(widthMm: 60, heightMm: 40)
        .gap(gapMm: 2)
        .cls()
        .text(x: 20, y: 20, text: 'MÃ: $partNo')
        .barcode(x: 20, y: 70, content: partNo)
        .print();

    await printer.printJob(job);
    await printer.disconnect();
  }

  @override
  void dispose() {
    _pdaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScanFlashOverlay(
      controller: _flashController,
      child: Scaffold(
        appBar: AppBar(title: const Text('Kiểm Đếm Nhà Xưởng')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              IndustrialStatusBanner(
                status: _status,
                message: _message,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
