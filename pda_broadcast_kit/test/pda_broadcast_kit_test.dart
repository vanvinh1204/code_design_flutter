import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pda_broadcast_kit/pda_broadcast_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('extractBarcodeFromEvent', () {
    test('ưu tiên resolvedBarcode do native đã giải mã sẵn', () {
      final raw = extractBarcodeFromEvent({
        'resolvedBarcode': 'ABC-001',
        'com.symbol.datawedge.data_string': 'KHAC',
      });
      expect(raw, 'ABC-001');
    });

    test('đọc data_string của Zebra ở cấp cao nhất', () {
      expect(
        extractBarcodeFromEvent({'com.symbol.datawedge.data_string': 'ZEBRA-1'}),
        'ZEBRA-1',
      );
    });

    test('đọc các khóa iData trong extras theo thứ tự ưu tiên', () {
      expect(
        extractBarcodeFromEvent({
          'extras': {'value': 'IDATA-VALUE', 'barcode': 'IDATA-BARCODE'},
        }),
        'IDATA-VALUE',
      );
      expect(
        extractBarcodeFromEvent({
          'extras': {'barcode': '', 'data': 'IDATA-DATA'},
        }),
        'IDATA-DATA',
      );
      expect(
        extractBarcodeFromEvent({
          'extras': {'result': 'IDATA-RESULT'},
        }),
        'IDATA-RESULT',
      );
    });

    test('đọc decode_data (danh sách map) của Zebra khi không có data_string', () {
      final raw = extractBarcodeFromEvent({
        'extras': {
          'com.symbol.datawedge.decode_data': [
            {'data': ''},
            {'data': 'DECODE-2'},
          ],
        },
      });
      expect(raw, 'DECODE-2');
    });

    test('rơi về data cấp cao nhất nhưng bỏ qua content:// URI', () {
      expect(extractBarcodeFromEvent({'data': 'PLAIN'}), 'PLAIN');
      expect(
        extractBarcodeFromEvent({'data': 'content://com.symbol.datawedge/x'}),
        '',
      );
    });

    test('trả chuỗi rỗng khi payload không có mã', () {
      expect(extractBarcodeFromEvent({}), '');
      expect(extractBarcodeFromEvent({'extras': 'khong-phai-map'}), '');
      expect(
        extractBarcodeFromEvent({
          'extras': {'value': 42},
        }),
        '',
      );
    });
  });

  group('PdaBroadcastController.addEvent', () {
    test('cập nhật lastBarcode, receivedCount, status và báo listener', () {
      final c = PdaBroadcastController(eventChannelName: 'test/events');
      var notified = 0;
      c.addListener(() => notified++);

      c.addEvent({'resolvedBarcode': 'A1'});
      c.addEvent({'khong_co_ma': true});

      expect(c.receivedCount, 2);
      expect(c.lastBarcode, 'A1', reason: 'sự kiện không có mã không xóa mã cũ');
      expect(c.status, 'Received');
      expect(c.history.first, {'khong_co_ma': true}, reason: 'mới nhất đứng đầu');
      expect(notified, 2);
      c.dispose();
    });

    test('history bị cắt ở maxHistory nhưng receivedCount vẫn tăng', () {
      final c = PdaBroadcastController(eventChannelName: 'test/events', maxHistory: 3);
      for (var i = 0; i < 5; i++) {
        c.addEvent({'resolvedBarcode': 'B$i'});
      }
      expect(c.history.length, 3);
      expect(c.history.map((e) => e['resolvedBarcode']), ['B4', 'B3', 'B2']);
      expect(c.receivedCount, 5);
      c.dispose();
    });

    test('clear() xóa lịch sử và mã cuối, đặt lại status', () {
      final c = PdaBroadcastController(eventChannelName: 'test/events');
      c.addEvent({'resolvedBarcode': 'C1'});
      c.clear();
      expect(c.history, isEmpty);
      expect(c.lastBarcode, '');
      expect(c.status, 'Listening…');
      c.dispose();
    });
  });

  group('PdaBroadcastController với EventChannel giả lập', () {
    const channelName = 'test/broadcast_events';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      messenger.setMockStreamHandler(const EventChannel(channelName), null);
    });

    testWidgets('nhận map từ native và giải mã thành lastBarcode', (tester) async {
      messenger.setMockStreamHandler(
        const EventChannel(channelName),
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.success({
              'action': 'com.symbol.datawedge.api.RESULT_ACTION',
              'extras': {'com.symbol.datawedge.data_string': 'ZEBRA-999'},
            });
            events.success('chuoi-khong-phai-map');
          },
        ),
      );

      final c = PdaBroadcastController(eventChannelName: channelName);
      c.startListening();
      expect(c.status, 'Listening…');
      await tester.pump();

      expect(c.receivedCount, 2);
      expect(c.lastBarcode, 'ZEBRA-999');
      expect(c.history.first, {'raw': 'chuoi-khong-phai-map'});
      expect(c.status, 'Received');
      c.dispose();
    });

    testWidgets('lỗi từ native ghi vào status, không ném ra ngoài', (tester) async {
      messenger.setMockStreamHandler(
        const EventChannel(channelName),
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events.error(code: 'E1', message: 'receiver chưa đăng ký');
          },
        ),
      );

      final c = PdaBroadcastController(eventChannelName: channelName);
      c.startListening();
      await tester.pump();

      expect(c.status, startsWith('Error:'));
      expect(c.status, contains('receiver chưa đăng ký'));
      c.dispose();
    });
  });

  group('PdaBroadcastController với MethodChannel DataWedge giả lập', () {
    const methodName = 'test/datawedge';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      messenger.setMockMethodCallHandler(const MethodChannel(methodName), null);
    });

    test('không có methodChannelName thì không gọi native và không đổi status', () async {
      final c = PdaBroadcastController(eventChannelName: 'test/events');
      expect(c.hasDataWedgeChannel, isFalse);
      await c.startScan();
      await c.loadDiagnostics();
      expect(c.status, 'Not listening');
      expect(c.diagnostics, isNull);
      c.dispose();
    });

    test('startScan gọi đúng method và đặt status thành công', () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(const MethodChannel(methodName), (call) async {
        calls.add(call.method);
        return null;
      });

      final c = PdaBroadcastController(
        eventChannelName: 'test/events',
        methodChannelName: methodName,
      );
      expect(c.hasDataWedgeChannel, isTrue);
      await c.startScan();
      await c.switchToAppProfile();

      expect(calls, ['startScan', 'switchToAppProfile']);
      expect(c.status, contains('SWITCH_TO_PROFILE'));
      c.dispose();
    });

    test('loadDiagnostics nhận map từ native; lỗi thì ghi error', () async {
      var fail = false;
      messenger.setMockMethodCallHandler(const MethodChannel(methodName), (call) async {
        if (fail) throw PlatformException(code: 'X');
        return {'profile': 'AppProfile', 'enabled': true};
      });

      final c = PdaBroadcastController(
        eventChannelName: 'test/events',
        methodChannelName: methodName,
      );
      await c.loadDiagnostics();
      expect(c.diagnostics, {'profile': 'AppProfile', 'enabled': true});

      fail = true;
      await c.loadDiagnostics();
      expect(c.diagnostics, {'error': 'getDiagnostics failed'});
      c.dispose();
    });

    test('native ném lỗi thì status ghi tên method và lỗi', () async {
      messenger.setMockMethodCallHandler(const MethodChannel(methodName), (call) async {
        throw PlatformException(code: 'NO_DW', message: 'DataWedge chưa cài');
      });

      final c = PdaBroadcastController(
        eventChannelName: 'test/events',
        methodChannelName: methodName,
      );
      await c.enableDataWedge();
      expect(c.status, startsWith('enableDataWedge:'));
      expect(c.status, contains('DataWedge chưa cài'));
      c.dispose();
    });
  });
}
