package com.pda_broadcast_kit

import android.os.Bundle

/** Cấu hình plugin (BARCODE / INTENT / KEYSTROKE) gửi trong SET_CONFIG. */
internal object DataWedgePluginBundles {
  fun barcodePluginBundle(): Bundle =
    Bundle().apply {
      putString("PLUGIN_NAME", "BARCODE")
      putString("RESET_CONFIG", "true")
      putBundle(
        "PARAM_LIST",
        Bundle().apply {
          putString("scanner_selection", "auto")
          putString("scanner_input_enabled", "true")
          putString("decoder_qr_code", "true")
          putString("decoder_datamatrix", "true")
        },
      )
    }

  fun intentPluginBundle(scanIntentAction: String): Bundle =
    Bundle().apply {
      putString("PLUGIN_NAME", "INTENT")
      putString("RESET_CONFIG", "true")
      putBundle(
        "PARAM_LIST",
        Bundle().apply {
          putString("intent_output_enabled", "true")
          putString("intent_action", scanIntentAction)
          putString("intent_category", "android.intent.category.DEFAULT")
          putString("intent_delivery", "2")
        },
      )
    }

  fun keystrokePluginBundle(): Bundle =
    Bundle().apply {
      putString("PLUGIN_NAME", "KEYSTROKE")
      putString("RESET_CONFIG", "true")
      putBundle(
        "PARAM_LIST",
        Bundle().apply {
          putString("keystroke_output_enabled", "false")
        },
      )
    }

  /**
   * Gắn toàn bộ Activity của app với profile ([ACTIVITY_LIST] = * theo TechDocs Zebra).
   * Trước đây dùng tên class đầy đủ — một số thiết bị/DataWedge không nhận, khiến profile “trống” association.
   */
  fun appAssociationBundle(packageName: String): Bundle =
    Bundle().apply {
      putString("PACKAGE_NAME", packageName)
      putStringArray("ACTIVITY_LIST", arrayOf("*"))
    }
}
