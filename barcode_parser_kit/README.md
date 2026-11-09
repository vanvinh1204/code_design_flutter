# barcode_parser_kit

Package **Dart thuần** làm sạch chuỗi quét thô và bóc tách mã vạch / QR công nghiệp theo schema phân cách.

Kit **bắt buộc** trong bộ chuẩn app PDA. Tag: `barcode_parser_kit-vX.Y.Z`. Lịch sử: [CHANGELOG.md](./CHANGELOG.md).

## 1. Khai báo

```yaml
dependencies:
  barcode_parser_kit:
    git:
      url: https://github.com/vanvinh1204/code_design_flutter.git
      path: barcode_parser_kit
      ref: barcode_parser_kit-v0.1.0
```

Yêu cầu: Dart `^3.12.0`. Không phụ thuộc Flutter, dùng được trong `domain/`.

## 2. API chính

| Thành phần | Vai trò |
| :--- | :--- |
| `BarcodeCleaner.clean(raw)` | Bỏ ký tự điều khiển (STX, ETX, CR, LF, NUL, ...) và khoảng trắng hai đầu. |
| `BarcodeCleaner.stripSurround(raw, prefix:, suffix:)` | Bỏ tiền tố / hậu tố do scanner tự thêm. |
| `DelimiterSchema(id:, delimiter:, fieldKeys:, minSegments:)` | Một cách bóc tách: cắt theo `delimiter`, gán tên trường theo thứ tự `fieldKeys`; khớp khi số đoạn >= `minSegments` (mặc định = số trường). |
| `BarcodeParser(schemas:, defaultDelimiter:)` | Thử lần lượt các schema; không khớp thì cắt theo `defaultDelimiter`; vẫn không thì trả chuỗi đơn. Luôn `clean()` trước. |
| `ParsedBarcode` | Kết quả: `rawText`, `segments`, `fields`, `formatId`; tiện ích `get(key)` (rỗng nếu thiếu) và `has(key)`. |

## 3. Ví dụ

```dart
import 'package:barcode_parser_kit/barcode_parser_kit.dart';

const parser = BarcodeParser(
  schemas: [
    DelimiterSchema(
      id: 'kanban_pipe',
      delimiter: '|',
      fieldKeys: ['partNo', 'qty', 'lot', 'date'],
    ),
    DelimiterSchema(
      id: 'pallet_at',
      delimiter: '@',
      fieldKeys: ['palletNo', 'qty'],
    ),
  ],
  defaultDelimiter: ';',
);

final r = parser.parse('\x02ABC-001|50|LOT2026|2026-11-09\r\n');
r.formatId;       // 'kanban_pipe'
r.get('partNo');  // 'ABC-001'
r.has('qty');     // true

parser.parse('A;B;C').segments;   // ['A', 'B', 'C'], formatId null
parser.parse('SINGLE').rawText;   // 'SINGLE', segments rỗng
```

## 4. Test

```bash
flutter test   # hoặc: dart test
```
