/// Kit dùng chung cho app thử PDA: broadcast → Flutter qua [EventChannel],
/// giải mã chuỗi quét, tùy chọn điều khiển DataWedge (Zebra) qua [MethodChannel].
///
/// **Android:** plugin đăng ký sẵn native (`PdaBroadcastKitPlugin`) — không cần chép Kotlin
/// vào app; chỉ cần `flutter pub add` / dependency và dùng đúng tên kênh [PdaBroadcastChannels].
library;

export 'src/barcode_from_event.dart';
export 'src/channel_names.dart';
export 'src/pda_broadcast_controller.dart';
export 'src/widgets/pda_broadcast_debug_page.dart';
