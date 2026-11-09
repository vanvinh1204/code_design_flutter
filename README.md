# Hệ Thống Module Dùng Chung Cho Flutter (Industrial & PDA Ecosystem)

Kho lưu trữ các package Flutter/Dart độc lập, chuẩn kiến trúc **Deep Module**, dùng chung cho các ứng dụng trong môi trường nhà máy, kho vận, thiết bị PDA và in tem nhãn.

Repo: `https://github.com/vanvinh1204/code_design_flutter.git`. Mỗi kit có version, `CHANGELOG.md`, `README.md` và tag riêng.

---

## 1. Danh sách kit

| Kit | Loại | Bắt buộc | Mô tả |
| :--- | :--- | :---: | :--- |
| [`pda_broadcast_kit`](./pda_broadcast_kit/) | Plugin Android | Có | Nhận broadcast quét mã từ PDA (Zebra DataWedge, iData) qua `EventChannel`, điều khiển DataWedge qua `MethodChannel`. |
| [`barcode_parser_kit`](./barcode_parser_kit/) | Dart thuần | Có | Làm sạch ký tự điều khiển (`\r`, `\n`, STX, ETX) và bóc tách chuỗi mã vạch / QR theo schema phân cách (`\|`, `@`, `,`). |
| [`industrial_feedback_kit`](./industrial_feedback_kit/) | Flutter package | Có | Phản hồi rung + âm thanh PASS / FAIL / WARNING chuẩn nhà xưởng. |
| [`industrial_ui_kit`](./industrial_ui_kit/) | Flutter package | Có | `ScanFocusKeeper` (giữ con trỏ quét), `IndustrialStatusBanner` (PASS/FAIL khổ lớn), `ScanFlashOverlay` (chớp màn hình). |
| [`tspl_printer_kit`](./tspl_printer_kit/) | Dart thuần | Không | Sinh lệnh in tem TSPL (Text, Barcode 1D, QR, Box, Bar) và gửi qua TCP Socket cổng 9100. |

### Quy tắc kit bắt buộc và kit tùy chọn

- **Bộ chuẩn (bắt buộc)** cho mọi app PDA / quét mã theo chuẩn dự án: `pda_broadcast_kit`, `barcode_parser_kit`, `industrial_feedback_kit`, `industrial_ui_kit`. App mới khai báo đủ bốn kit này ngay từ đầu, kể cả khi chưa dùng hết.
- **Tùy chọn**: `tspl_printer_kit`, chỉ khai báo khi app có nghiệp vụ in tem nhãn TSPL.
- App không chép code của kit vào `lib/`; cần sửa kit thì sửa trong repo này và phát hành tag mới (mục 4).

### Yêu cầu SDK tối thiểu

| Thành phần | Phiên bản |
| :--- | :--- |
| Dart SDK | `^3.12.0` |
| Flutter | `>=3.44.0` (các kit phụ thuộc `flutter`) |

Hai kit Dart thuần (`barcode_parser_kit`, `tspl_printer_kit`) chỉ cần Dart; ba kit còn lại cần Flutter. Nâng SDK tối thiểu là thay đổi **minor** của kit và phải ghi vào CHANGELOG.

---

## 2. Khai báo trong `pubspec.yaml` của app

Luôn ghim theo **tag** bằng `git:` + `path:` + `ref:` (mục 4 chuẩn dự án). Tag hiện tại của từng kit: `pda_broadcast_kit-v0.2.1`, `barcode_parser_kit-v0.1.0`, `industrial_feedback_kit-v0.1.0`, `industrial_ui_kit-v0.1.0`, `tspl_printer_kit-v0.1.0`.

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Bộ chuẩn (bắt buộc)
  pda_broadcast_kit:
    git:
      url: https://github.com/vanvinh1204/code_design_flutter.git
      path: pda_broadcast_kit
      ref: pda_broadcast_kit-v0.2.1
  barcode_parser_kit:
    git:
      url: https://github.com/vanvinh1204/code_design_flutter.git
      path: barcode_parser_kit
      ref: barcode_parser_kit-v0.1.0
  industrial_feedback_kit:
    git:
      url: https://github.com/vanvinh1204/code_design_flutter.git
      path: industrial_feedback_kit
      ref: industrial_feedback_kit-v0.1.0
  industrial_ui_kit:
    git:
      url: https://github.com/vanvinh1204/code_design_flutter.git
      path: industrial_ui_kit
      ref: industrial_ui_kit-v0.1.0

  # Tùy chọn: chỉ khi app có in tem nhãn
  # tspl_printer_kit:
  #   git:
  #     url: https://github.com/vanvinh1204/code_design_flutter.git
  #     path: tspl_printer_kit
  #     ref: tspl_printer_kit-v0.1.0
```

### Sửa kit song song với app: `pubspec_overrides.yaml`

Không đổi `pubspec.yaml` sang `path:`. Tạo file `pubspec_overrides.yaml` cạnh `pubspec.yaml` của app (file này **không commit**, đã nằm trong `.gitignore` mẫu của chuẩn):

```yaml
# pubspec_overrides.yaml  (không commit)
dependency_overrides:
  pda_broadcast_kit:
    path: ../code_design_flutter/pda_broadcast_kit
  barcode_parser_kit:
    path: ../code_design_flutter/barcode_parser_kit
```

`flutter pub get` sẽ ưu tiên bản local. Xóa file này (hoặc xóa mục tương ứng) để quay về bản ghim tag. Khi kit đã ổn, phát hành tag mới rồi nâng `ref:` trong `pubspec.yaml` của app trong một commit riêng.

---

## 3. Ví dụ kết hợp trọn quy trình quét → bóc tách → phản hồi → in

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
  // Tên kênh phải khớp native: dùng hằng trong PdaBroadcastChannels.
  final _pda = PdaBroadcastController(
    eventChannelName: PdaBroadcastChannels.zebraTc21Broadcast,
    methodChannelName: PdaBroadcastChannels.zebraTc21DataWedge, // bỏ nếu không phải Zebra
  );
  final _feedback = const IndustrialFeedback();
  final _flash = ScanFlashController();
  final _parser = const BarcodeParser(
    schemas: [
      DelimiterSchema(
        id: 'kanban',
        delimiter: '|',
        fieldKeys: ['partNo', 'qty', 'lotNo'],
      ),
    ],
  );

  int _seenCount = 0;
  IndustrialStatus _status = IndustrialStatus.idle;
  String _message = 'SẴN SÀNG QUÉT';

  @override
  void initState() {
    super.initState();
    _pda.addListener(_onPdaChanged);
    _pda.startListening();
  }

  // Controller là ChangeNotifier: so receivedCount để biết có lần quét mới.
  void _onPdaChanged() {
    if (_pda.receivedCount == _seenCount) return;
    _seenCount = _pda.receivedCount;
    final raw = _pda.lastBarcode;
    if (raw.isNotEmpty) _onBarcodeReceived(raw);
  }

  Future<void> _onBarcodeReceived(String raw) async {
    final parsed = _parser.parse(raw);

    if (parsed.has('partNo')) {
      setState(() {
        _status = IndustrialStatus.pass;
        _message = '${parsed.get('partNo')} (SL: ${parsed.get('qty')})';
      });
      await _feedback.notifySuccess(); // rung dứt khoát + beep
      _flash.flashSuccess();           // chớp xanh toàn màn hình
      // await _printLabel(parsed.get('partNo'), parsed.get('qty'));
    } else {
      setState(() {
        _status = IndustrialStatus.fail;
        _message = 'Mã không đúng định dạng';
      });
      await _feedback.notifyError();   // rung kép + âm cảnh báo
      _flash.flashError();             // chớp đỏ
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
        .text(x: 20, y: 150, text: 'SL: $qty')
        .print();
    try {
      await printer.printJob(job);
    } finally {
      await printer.disconnect();
    }
  }

  @override
  void dispose() {
    _pda.removeListener(_onPdaChanged);
    _pda.dispose();
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScanFlashOverlay(
      controller: _flash,
      child: Scaffold(
        appBar: AppBar(title: const Text('Kiểm Đếm Nhà Xưởng')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              IndustrialStatusBanner(status: _status, message: _message),
            ],
          ),
        ),
      ),
    );
  }
}
```

Chi tiết API từng kit xem `README.md` trong thư mục kit.

---

## 4. Phát hành và ghim version

- **Tag theo từng kit**: `<kit>-vX.Y.Z`, ví dụ `pda_broadcast_kit-v0.2.1`. Version trong tag luôn bằng `version:` trong `pubspec.yaml` của kit đó.
- **CHANGELOG riêng từng kit**: `<kit>/CHANGELOG.md` theo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/), tiêu đề con tiếng Việt (`Đã thêm (Added)`, `Đã thay đổi (Changed)`, `Đã sửa (Fixed)`, `Ngừng khuyến nghị (Deprecated)`, `Đã xóa (Removed)`). Mọi thay đổi ghi vào mục `[Unreleased]` của kit ngay trong commit sửa code.
- **Script phát hành** `python tools/release.py <kit>` (không có cờ, mọi lựa chọn hỏi trong CLI; bỏ tên kit thì chọn trong menu). Script kiểm git sạch và đang ở nhánh `main`, chọn patch / minor / major, ghi version vào `pubspec.yaml` của kit, đổi `[Unreleased]` trong CHANGELOG của kit thành `[X.Y.Z] - <ngày>`, chạy `flutter test` trong kit (lỗi thì trả file về như cũ), commit `chore(release): bump <kit> to X.Y.Z`, tag `<kit>-vX.Y.Z`, rồi hỏi mới push (có `gh` thì tạo GitHub Release từ CHANGELOG). Test của script: `python tools/test_release.py`.
- **Nâng tag ở app**: dự án mới ghim tag mới nhất của từng kit; dự án đang chạy chỉ nâng khi cần tính năng / bản sửa lỗi, nâng trong một commit riêng.
- **`pubspec.lock` không commit** trong repo này (package thư viện, app tự phân giải). App theo chuẩn vẫn commit `pubspec.lock` của app.

---

## 5. Phát triển trong repo

```bash
cd <kit>
flutter pub get
flutter test          # dùng được cho cả kit Dart thuần
```

- Mỗi kit tự chứa: `lib/`, `test/`, `pubspec.yaml`, `CHANGELOG.md`, `README.md`. Kit không phụ thuộc chéo nhau.
- **`pubspec.yaml` của kit chỉ dùng ASCII** (mô tả viết tiếng Anh). Lý do: pub trên Windows đọc pubspec của git dependency qua `git show` và giải mã theo code page hệ thống, ký tự tiếng Việt làm `flutter pub get` ở app lỗi `Unexpected character`. Script phát hành từ chối chạy nếu vi phạm. Tiếng Việt vẫn dùng bình thường trong `README.md`, `CHANGELOG.md` và code.
- Quy tắc làm việc với agent: `AGENTS.md`, `docs/agents/`.
