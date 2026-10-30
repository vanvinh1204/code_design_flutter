import 'dart:convert';
import 'transport.dart';
import 'tspl_builder.dart';

/// Bộ điều khiển máy in tem nhãn TSPL (Deep Module)
class TsplPrinter {
  final TsplTransport transport;
  final Encoding encoding;

  TsplPrinter({
    required this.transport,
    this.encoding = utf8,
  });

  /// Tạo máy in qua mạng LAN TCP/IP nhanh
  factory TsplPrinter.network(
    String ipAddress, {
    int port = 9100,
    Duration timeout = const Duration(seconds: 5),
    Encoding encoding = utf8,
  }) {
    return TsplPrinter(
      transport: TcpTransport(host: ipAddress, port: port, timeout: timeout),
      encoding: encoding,
    );
  }

  /// Mở kết nối tới máy in
  Future<void> connect() => transport.connect();

  /// Gửi một lệnh in hoàn chỉnh từ TsplBuilder
  Future<void> printJob(TsplBuilder builder) async {
    final bytes = builder.buildBytes(encoding: encoding);
    await transport.send(bytes);
  }

  /// Đóng kết nối
  Future<void> disconnect() => transport.disconnect();

  /// Kiểm tra trạng thái kết nối
  bool get isConnected => transport.isConnected;
}
