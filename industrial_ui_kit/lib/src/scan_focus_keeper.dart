import 'package:flutter/material.dart';

/// Widget chuyên dụng duy trì tiêu điểm (Focus) cho máy quét mã vạch HID / PDA.
/// Khi công nhân vô tình chạm vào màn hình hoặc sau khi đóng popup,
/// widget này sẽ tự động khôi phục lại Focus cho [focusNode].
class ScanFocusKeeper extends StatefulWidget {
  final FocusNode focusNode;
  final Widget child;

  /// Tạm dừng việc tự động lấy lại focus (ví dụ khi đang mở hộp thoại nhập tay)
  final bool isPaused;

  /// Độ trễ trước khi đòi lại focus (mặc định 100ms)
  final Duration refocusDelay;

  const ScanFocusKeeper({
    super.key,
    required this.focusNode,
    required this.child,
    this.isPaused = false,
    this.refocusDelay = const Duration(milliseconds: 100),
  });

  @override
  State<ScanFocusKeeper> createState() => _ScanFocusKeeperState();
}

class _ScanFocusKeeperState extends State<ScanFocusKeeper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.focusNode.addListener(_onFocusChange);
    _ensureFocus();
  }

  @override
  void didUpdateWidget(covariant ScanFocusKeeper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
    if (!widget.isPaused && oldWidget.isPaused) {
      _ensureFocus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !widget.isPaused) {
      _ensureFocus();
    }
  }

  void _onFocusChange() {
    if (!widget.focusNode.hasFocus && !widget.isPaused && mounted) {
      Future.delayed(widget.refocusDelay, () {
        if (mounted && !widget.isPaused && !widget.focusNode.hasFocus) {
          widget.focusNode.requestFocus();
        }
      });
    }
  }

  void _ensureFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.isPaused && !widget.focusNode.hasFocus) {
        widget.focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (!widget.isPaused) {
          _ensureFocus();
        }
      },
      child: widget.child,
    );
  }
}
