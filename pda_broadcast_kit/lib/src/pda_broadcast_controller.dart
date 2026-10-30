import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'barcode_from_event.dart';

/// Điều khiển lắng nghe [EventChannel] và (tuỳ chọn) gọi DataWedge qua [MethodChannel].
class PdaBroadcastController extends ChangeNotifier {
  PdaBroadcastController({
    required this.eventChannelName,
    this.methodChannelName,
    this.maxHistory = 50,
  });

  final String eventChannelName;
  final String? methodChannelName;
  final int maxHistory;

  late final EventChannel _events = EventChannel(eventChannelName);
  MethodChannel? get _methods =>
      methodChannelName != null ? MethodChannel(methodChannelName!) : null;

  StreamSubscription<dynamic>? _sub;

  String status = 'Not listening';
  String lastBarcode = '';
  int receivedCount = 0;
  final List<Map<String, dynamic>> history = <Map<String, dynamic>>[];
  Map<String, dynamic>? diagnostics;

  bool get hasDataWedgeChannel => methodChannelName != null;

  /// Ghi một broadcast vào lịch sử. [history] bị cắt ở [maxHistory], nên số phần tử
  /// không tăng mãi; người nghe phải dựa vào lần gọi này, không dựa vào độ dài.
  void addEvent(Map<String, dynamic> event) {
    receivedCount++;
    history.insert(0, event);
    if (history.length > maxHistory) {
      history.removeLast();
    }
    status = 'Received';
    final decoded = extractBarcodeFromEvent(event);
    if (decoded.isNotEmpty) {
      lastBarcode = decoded;
    }
    notifyListeners();
  }

  void startListening() {
    _sub?.cancel();
    status = 'Listening…';
    notifyListeners();

    _sub = _events.receiveBroadcastStream().listen(
      (event) {
        final mapped = (event is Map)
            ? Map<String, dynamic>.from(event)
            : <String, dynamic>{'raw': event};
        addEvent(mapped);
      },
      onError: (Object e) {
        status = 'Error: $e';
        notifyListeners();
      },
      cancelOnError: false,
    );
  }

  void clear() {
    history.clear();
    lastBarcode = '';
    status = 'Listening…';
    notifyListeners();
  }

  Future<void> loadDiagnostics() async {
    final ch = _methods;
    if (ch == null) return;
    try {
      final m = await ch.invokeMethod<dynamic>('getDiagnostics');
      if (m is Map) {
        diagnostics = Map<String, dynamic>.from(m);
      } else {
        diagnostics = null;
      }
      notifyListeners();
    } catch (_) {
      diagnostics = {'error': 'getDiagnostics failed'};
      notifyListeners();
    }
  }

  Future<void> switchToAppProfile() async {
    await _invokeDataWedge(
      'switchToAppProfile',
      okStatus: 'Đã gửi SWITCH_TO_PROFILE — xem History: datawedge_api_result',
    );
  }

  Future<void> startScan() async {
    await _invokeDataWedge(
      'startScan',
      okStatus: 'Đã gửi START_SCANNING — xem History (RESULT/INPUT_NOT_ENABLED…)',
    );
  }

  Future<void> enableDataWedge() async {
    await _invokeDataWedge('enableDataWedge', okStatus: 'Đã gửi ENABLE_DATAWEDGE(true)');
  }

  Future<void> reapplyProfile() async {
    await _invokeDataWedge(
      'reapplyProfile',
      okStatus: 'Re-apply profile (CREATE + SET_CONFIG per-plugin)…',
    );
  }

  Future<void> getActiveProfile() async {
    await _invokeDataWedge(
      'getActiveProfile',
      okStatus: 'GET_ACTIVE_PROFILE — xem History: datawedge_api_result',
    );
  }

  Future<void> _invokeDataWedge(String method, {required String okStatus}) async {
    final ch = _methods;
    if (ch == null) return;
    try {
      await ch.invokeMethod<void>(method);
      status = okStatus;
      notifyListeners();
    } catch (e) {
      status = '$method: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
