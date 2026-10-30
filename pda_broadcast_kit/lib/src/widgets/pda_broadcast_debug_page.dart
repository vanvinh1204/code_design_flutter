import 'package:flutter/material.dart';

import '../barcode_from_event.dart';
import '../pda_broadcast_controller.dart';

/// Trang debug: status, mã quét lớn, lịch sử; tuỳ chọn nút DataWedge (Zebra).
class PdaBroadcastDebugPage extends StatefulWidget {
  const PdaBroadcastDebugPage({
    super.key,
    required this.controller,
    required this.title,
    this.hintText,
    this.showDataWedgeControls = false,
    this.showZebraIntentHint = false,
    this.leading,
  });

  final PdaBroadcastController controller;
  final String title;
  final String? hintText;
  final bool showDataWedgeControls;
  final bool showZebraIntentHint;
  final Widget? leading;

  @override
  State<PdaBroadcastDebugPage> createState() => _PdaBroadcastDebugPageState();
}

class _PdaBroadcastDebugPageState extends State<PdaBroadcastDebugPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCtrl);
    if (widget.controller.hasDataWedgeChannel) {
      widget.controller.loadDiagnostics();
    }
  }

  void _onCtrl() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant PdaBroadcastDebugPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onCtrl);
      widget.controller.addListener(_onCtrl);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCtrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final last = c.history.isEmpty ? null : c.history.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: widget.leading,
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            tooltip: 'Restart listening',
            onPressed: c.startListening,
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: c.clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: ${c.status}', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Material(
              elevation: 1,
              borderRadius: BorderRadius.circular(12),
              color: c.lastBarcode.isEmpty ? cs.surfaceContainerHighest : cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Kết quả quét',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: c.lastBarcode.isEmpty ? cs.onSurfaceVariant : cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      c.lastBarcode.isEmpty ? '— Chưa có dữ liệu mã —' : c.lastBarcode,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                        color: c.lastBarcode.isEmpty ? cs.onSurfaceVariant : cs.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.hintText != null) ...[
              const SizedBox(height: 8),
              Text(widget.hintText!, style: theme.textTheme.bodySmall),
            ],
            if (widget.showDataWedgeControls) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: _compactBtn,
                      onPressed: c.switchToAppProfile,
                      icon: const Icon(Icons.swap_horiz, size: 10),
                      label: const Text('Ép profile DataWedge'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: _compactBtn,
                      onPressed: c.startScan,
                      icon: const Icon(Icons.qr_code_scanner, size: 10),
                      label: const Text('Soft scan (START)'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: _compactOutlined,
                      onPressed: c.enableDataWedge,
                      icon: const Icon(Icons.power_settings_new, size: 10),
                      label: const Text('Bật DW'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: _compactBtn,
                      onPressed: c.reapplyProfile,
                      icon: const Icon(Icons.build, size: 10),
                      label: const Text('Re-apply profile (per-plugin)'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: _compactOutlined,
                      onPressed: c.getActiveProfile,
                      icon: const Icon(Icons.info_outline, size: 10),
                      label: const Text('Active profile?'),
                    ),
                  ),
                ],
              ),
            ],
            if (widget.showZebraIntentHint) ...[
              const SizedBox(height: 6),
              Text(
                'Giống flutter_datawedge: action quét = <package>.SCAN_EVENT; IntentFilter + DEFAULT category.',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Text('Last event:', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.topLeft,
              child: SelectableText(
                (last ?? const <String, dynamic>{'info': 'No events yet'}).toString(),
                style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 1),
            Text('History (newest first):', style: theme.textTheme.titleSmall),
            const SizedBox(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: c.history.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = c.history[i];
                final kind = e['kind']?.toString() ?? '';
                final action = e['action']?.toString() ?? '(no action)';
                if (kind == 'datawedge_api_result') {
                  final res = e['RESULT']?.toString() ?? '';
                  final cmd = e['COMMAND']?.toString() ?? '';
                  final ri = e['RESULT_INFO']?.toString() ?? '';
                  return ListTile(
                    dense: true,
                    title: Text('DW API: $cmd → $res', maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: ri.isEmpty ? null : Text(ri, maxLines: 4, overflow: TextOverflow.ellipsis),
                  );
                }
                if (kind == 'scan_broadcast' || kind == 'scan_activity_intent') {
                  final line = extractBarcodeFromEvent(e);
                  final actionLabel = e['action']?.toString() ?? '';
                  return ListTile(
                    dense: true,
                    title: Text(line.isEmpty ? actionLabel : line, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      kind == 'scan_activity_intent' ? 'Activity intent · $actionLabel' : actionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                final line = extractBarcodeFromEvent(e);
                return ListTile(
                  dense: true,
                  title: Text(action, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: line.isEmpty ? null : Text(line, maxLines: 2, overflow: TextOverflow.ellipsis),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static ButtonStyle get _compactBtn => FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        textStyle: const TextStyle(fontSize: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  static ButtonStyle get _compactOutlined => OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        textStyle: const TextStyle(fontSize: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}
