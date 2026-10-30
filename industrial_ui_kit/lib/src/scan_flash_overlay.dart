import 'package:flutter/material.dart';

/// Controller kích hoạt hiệu ứng chớp màu toàn màn hình (Flash Overlay)
class ScanFlashController extends ChangeNotifier {
  Color? _flashColor;
  Color? get flashColor => _flashColor;

  /// Chớp màu xanh lá cây (PASS)
  void flashSuccess({Duration duration = const Duration(milliseconds: 300)}) {
    _trigger(Colors.green.withAlpha(120), duration);
  }

  /// Chớp màu đỏ (FAIL/NG)
  void flashError({Duration duration = const Duration(milliseconds: 400)}) {
    _trigger(Colors.red.withAlpha(150), duration);
  }

  void _trigger(Color color, Duration duration) {
    _flashColor = color;
    notifyListeners();
    Future.delayed(duration, () {
      _flashColor = null;
      notifyListeners();
    });
  }
}

/// Widget phủ lớp chớp màu thị giác khi quét (Visual Peripheral Cue)
class ScanFlashOverlay extends StatelessWidget {
  final ScanFlashController controller;
  final Widget child;

  const ScanFlashOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  color: controller.flashColor ?? Colors.transparent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
