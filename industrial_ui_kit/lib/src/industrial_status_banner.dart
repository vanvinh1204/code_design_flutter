import 'package:flutter/material.dart';

/// Trạng thái kết quả quét hoặc thao tác trong nhà xưởng
enum IndustrialStatus {
  idle,
  processing,
  pass,
  fail,
}

/// Bảng hiển thị trạng thái công nghiệp khổ lớn, tương phản cao, dễ nhìn từ xa
class IndustrialStatusBanner extends StatelessWidget {
  final IndustrialStatus status;
  final String? message;
  final String? subMessage;
  final double height;

  const IndustrialStatusBanner({
    super.key,
    required this.status,
    this.message,
    this.subMessage,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor, defaultText, icon) = switch (status) {
      IndustrialStatus.pass => (
          Colors.green.shade700,
          Colors.white,
          'PASS / HỢP LỆ',
          Icons.check_circle_outline,
        ),
      IndustrialStatus.fail => (
          Colors.red.shade700,
          Colors.white,
          'FAIL / LỖI MÃ',
          Icons.error_outline,
        ),
      IndustrialStatus.processing => (
          Colors.blue.shade700,
          Colors.white,
          'ĐANG XỬ LÝ...',
          Icons.hourglass_empty,
        ),
      IndustrialStatus.idle => (
          Colors.grey.shade300,
          Colors.black87,
          'SẴN SÀNG QUÉT',
          Icons.qr_code_scanner,
        ),
    };

    final displayText = (message != null && message!.isNotEmpty) ? message! : defaultText;

    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: height * 0.45, color: fgColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayText,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: height * 0.24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subMessage != null && subMessage!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subMessage!,
                    style: TextStyle(
                      color: fgColor.withAlpha(220),
                      fontSize: height * 0.16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
