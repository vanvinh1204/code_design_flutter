/// Trích chuỗi mã vạch/mã quét từ payload native (map).
///
/// Gộp logic Zebra DataWedge (resolvedBarcode, data_string, decode_data, …)
/// và PDA iData (extras: value, barcode, data, result).
String extractBarcodeFromEvent(Map<String, dynamic> e) {
  final resolved = e['resolvedBarcode']?.toString();
  if (resolved != null && resolved.isNotEmpty) return resolved;

  final direct = e['com.symbol.datawedge.data_string']?.toString();
  if (direct != null && direct.isNotEmpty) return direct;

  final ex = e['extras'];
  if (ex is Map) {
    for (final k in [
      'com.symbol.datawedge.data_string',
      'com.symbol.datawedge.data',
      'value',
      'barcode',
      'data',
      'result',
    ]) {
      final v = ex[k];
      if (v is String && v.isNotEmpty) return v;
    }
    final decode = ex['com.symbol.datawedge.decode_data'];
    if (decode is List) {
      for (final item in decode) {
        if (item is Map) {
          final d = item['data'];
          if (d is String && d.isNotEmpty) return d;
        }
      }
    }
  }

  final d = e['data']?.toString();
  if (d != null && d.isNotEmpty && !d.startsWith('content://')) return d;
  return '';
}
