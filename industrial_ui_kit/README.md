# industrial_ui_kit

Widget giao diện công nghiệp cho app PDA / quét mã: giữ tiêu điểm cho scanner, bảng trạng thái PASS/FAIL khổ lớn, chớp màu toàn màn hình.

Kit **bắt buộc** trong bộ chuẩn app PDA. Tag: `industrial_ui_kit-vX.Y.Z`. Lịch sử: [CHANGELOG.md](./CHANGELOG.md).

## 1. Khai báo

```yaml
dependencies:
  industrial_ui_kit:
    git:
      url: https://github.com/vanvinh1204/code_design_flutter.git
      path: industrial_ui_kit
      ref: industrial_ui_kit-v0.1.0
```

Yêu cầu: Dart `^3.12.0`, Flutter `>=3.44.0`.

## 2. API chính

| Thành phần | Vai trò |
| :--- | :--- |
| `ScanFocusKeeper(focusNode:, child:, isPaused:, refocusDelay:)` | Tự đòi lại focus cho ô nhận dữ liệu scanner HID khi công nhân chạm màn hình, đóng popup hoặc app quay lại foreground. Đặt `isPaused: true` khi mở hộp thoại nhập tay. |
| `IndustrialStatusBanner(status:, message:, subMessage:, height:)` | Bảng trạng thái tương phản cao, nhìn được từ xa. |
| `IndustrialStatus` | `idle`, `processing`, `pass`, `fail` (mỗi trạng thái có màu, icon và chữ mặc định tiếng Việt). |
| `ScanFlashController` | `flashSuccess()` (xanh), `flashError()` (đỏ), tùy chỉnh `duration`. |
| `ScanFlashOverlay(controller:, child:)` | Bọc màn hình để chớp màu, không chặn thao tác chạm. |

## 3. Ví dụ

```dart
import 'package:flutter/material.dart';
import 'package:industrial_ui_kit/industrial_ui_kit.dart';

final flash = ScanFlashController();
final scanFocus = FocusNode();

Widget build(BuildContext context) {
  return ScanFlashOverlay(
    controller: flash,
    child: Scaffold(
      body: Column(
        children: [
          IndustrialStatusBanner(
            status: IndustrialStatus.pass,
            message: '82824-B1010',
            subMessage: 'SL: 50',
          ),
          // Ô nhận dữ liệu scanner HID, luôn giữ focus
          ScanFocusKeeper(
            focusNode: scanFocus,
            child: TextField(
              focusNode: scanFocus,
              onSubmitted: (raw) => flash.flashSuccess(),
            ),
          ),
        ],
      ),
    ),
  );
}
```

Với PDA dùng broadcast (`pda_broadcast_kit`) không cần `ScanFocusKeeper`; widget này dành cho scanner HID / bàn phím.

## 4. Test

```bash
flutter test
```
