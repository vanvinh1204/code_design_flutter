import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:industrial_ui_kit/industrial_ui_kit.dart';

void main() {
  group('IndustrialStatusBanner', () {
    testWidgets('renders PASS status correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IndustrialStatusBanner(
              status: IndustrialStatus.pass,
              message: 'KIỂM ĐẾM THÀNH CÔNG',
              subMessage: 'Mã: 82824-B1010',
            ),
          ),
        ),
      );

      expect(find.text('KIỂM ĐẾM THÀNH CÔNG'), findsOneWidget);
      expect(find.text('Mã: 82824-B1010'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders FAIL status correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IndustrialStatusBanner(
              status: IndustrialStatus.fail,
              message: 'SAI QUY CÁCH',
            ),
          ),
        ),
      );

      expect(find.text('SAI QUY CÁCH'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('ScanFocusKeeper', () {
    testWidgets('requests focus automatically', (tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScanFocusKeeper(
              focusNode: focusNode,
              child: TextField(focusNode: focusNode),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);

      focusNode.dispose();
    });
  });
}
