import 'dart:async';
import 'dart:io';

/// Giao diện trừu tượng cho kênh truyền dữ liệu tới máy in (Seam)
abstract interface class TsplTransport {
  /// Mở kết nối
  Future<void> connect();

  /// Gửi dữ liệu byte lệnh
  Future<void> send(List<int> bytes);

  /// Đóng kết nối
  Future<void> disconnect();

  /// Trạng thái đang kết nối hay không
  bool get isConnected;
}

/// Adapter kết nối máy in qua mạng LAN / Wi-Fi (TCP Socket port 9100)
class TcpTransport implements TsplTransport {
  final String host;
  final int port;
  final Duration timeout;

  Socket? _socket;

  TcpTransport({
    required this.host,
    this.port = 9100,
    this.timeout = const Duration(seconds: 5),
  });

  @override
  bool get isConnected => _socket != null;

  @override
  Future<void> connect() async {
    if (isConnected) return;
    _socket = await Socket.connect(host, port, timeout: timeout);
  }

  @override
  Future<void> send(List<int> bytes) async {
    if (!isConnected) {
      await connect();
    }
    _socket!.add(bytes);
    await _socket!.flush();
  }

  @override
  Future<void> disconnect() async {
    await _socket?.close();
    _socket?.destroy();
    _socket = null;
  }
}

/// Adapter giả lập phục vụ viết Unit Test hoặc chạy thử trên máy dev
class MockTransport implements TsplTransport {
  bool _connected = false;
  final List<List<int>> sentBytes = [];

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> send(List<int> bytes) async {
    if (!_connected) throw StateError('MockTransport chưa được kết nối');
    sentBytes.add(bytes);
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  void clear() {
    sentBytes.clear();
  }
}
