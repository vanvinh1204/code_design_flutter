package com.pda_broadcast_kit

import android.content.Intent
import android.os.Bundle

/** Đọc chuỗi barcode từ Intent DataWedge (broadcast hoặc Start Activity). */
internal object ScanIntentParser {
  /**
   * Thứ tự: data_string → decode_data[0] (ArrayList<Bundle>) → com.symbol.datawedge.data → intent.dataString.
   */
  fun resolveBarcodeString(intent: Intent): String? {
    val ds = intent.getStringExtra("com.symbol.datawedge.data_string")
    if (!ds.isNullOrEmpty()) return ds

    val decodeList: ArrayList<Bundle>? =
      try {
        @Suppress("UNCHECKED_CAST", "DEPRECATION")
        intent.getParcelableArrayListExtra<Bundle>("com.symbol.datawedge.decode_data")
      } catch (_: Exception) {
        null
      }
    if (decodeList != null) {
      for (b in decodeList) {
        val s: String? = when (val v = b.get("data")) {
          is String -> v
          is ByteArray -> String(v)
          else -> v?.toString()
        }
        if (!s.isNullOrEmpty()) return s
      }
    }

    val dd = intent.getStringExtra("com.symbol.datawedge.data")
    if (!dd.isNullOrEmpty()) return dd

    return intent.dataString
  }
}
