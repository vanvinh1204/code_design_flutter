import 'dart:convert';
import 'package:test/test.dart';
import 'package:tspl_printer_kit/tspl_printer_kit.dart';

void main() {
  group('TsplBuilder', () {
    test('generates expected TSPL command sequence', () {
      final builder = TsplBuilder()
          .size(widthMm: 60, heightMm: 40)
          .gap(gapMm: 2)
          .direction(1)
          .cls()
          .text(x: 10, y: 10, text: 'PART NO: 82824-B1010', font: '3')
          .barcode(x: 10, y: 50, content: '82824-B1010', height: 40)
          .qrcode(x: 200, y: 50, content: '82824-B1010|QTY:50')
          .print(count: 1);

      final cmd = builder.buildString();

      expect(cmd, contains('SIZE 60.0 mm, 40.0 mm'));
      expect(cmd, contains('GAP 2.0 mm, 0.0 mm'));
      expect(cmd, contains('DIRECTION 1'));
      expect(cmd, contains('CLS'));
      expect(cmd, contains('TEXT 10,10,"3",0,1,1,"PART NO: 82824-B1010"'));
      expect(cmd, contains('BARCODE 10,50,"128",40,1,0,2,4,"82824-B1010"'));
      expect(cmd, contains('QRCODE 200,50,M,4,A,0,"82824-B1010|QTY:50"'));
      expect(cmd, contains('PRINT 1,1'));
    });
  });

  group('TsplPrinter with MockTransport', () {
    test('connects, sends bytes, and disconnects', () async {
      final mock = MockTransport();
      final printer = TsplPrinter(transport: mock);

      expect(printer.isConnected, isFalse);
      await printer.connect();
      expect(printer.isConnected, isTrue);

      final builder = TsplBuilder().size(widthMm: 50, heightMm: 30).print();
      await printer.printJob(builder);

      expect(mock.sentBytes, hasLength(1));
      final decoded = utf8.decode(mock.sentBytes.first);
      expect(decoded, contains('PRINT 1,1'));

      await printer.disconnect();
      expect(printer.isConnected, isFalse);
    });
  });
}
