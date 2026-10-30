package com.pda_broadcast_kit

/** Intent action / extra dùng với DataWedge (Zebra). */
internal object DataWedgeConstants {
  const val DW_PACKAGE = "com.symbol.datawedge"
  const val DW_API_ACTION = "com.symbol.datawedge.api.ACTION"

  const val ACTION_RESULT = "com.symbol.datawedge.api.RESULT_ACTION"
  const val ACTION_NOTIFICATION = "com.symbol.datawedge.api.NOTIFICATION_ACTION"
  const val ACTION_SCANRESULT_COMPAT = "android.intent.action.SCANRESULT"

  /** Tên profile DataWedge do plugin tạo / cấu hình. */
  const val DW_PROFILE_NAME = "PdaBroadcastKit_Auto"

  /** Kết quả GET_PROFILES_LIST (mảng tên profile). TechDocs Zebra DataWedge. */
  const val RESULT_GET_PROFILES_LIST = "com.symbol.datawedge.api.RESULT_GET_PROFILES_LIST"
}
