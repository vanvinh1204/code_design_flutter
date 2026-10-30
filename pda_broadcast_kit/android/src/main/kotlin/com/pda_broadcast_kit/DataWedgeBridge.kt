package com.pda_broadcast_kit

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.ArrayDeque

/**
 * Zebra TC21 + DataWedge — căn theo flutter_datawedge:
 * - Action quét: packageName + ".SCAN_EVENT"
 * - Một [IntentFilter] gồm scan + RESULT + NOTIFICATION + [Intent.CATEGORY_DEFAULT].
 */
internal class DataWedgeBridge(
  private val activity: Activity,
) {
  companion object {
    private const val TAG = "PdaBroadcastKit"
    /** Nếu không nhận được chuỗi tạo profile qua GET_PROFILES_LIST (một số FW), vẫn gửi CREATE + SET_CONFIG. */
    private const val FALLBACK_PROFILE_SETUP_MS = 4000L
    /** Trễ gửi GET_PROFILES_LIST sau khi bật DataWedge (tránh race khi DW chưa sẵn sàng). */
    private const val DELAY_GET_PROFILES_LIST_MS = 900L
  }

  private val actionScanEvent: String
    get() = "${activity.packageName}.SCAN_EVENT"

  private val actionScanLegacy: String
    get() = "${activity.packageName}.SCAN"

  private var dwReceiver: BroadcastReceiver? = null
  private var eventSink: EventChannel.EventSink? = null
  private val pendingPayloads: ArrayDeque<HashMap<String, Any?>> = ArrayDeque()
  private val maxPending = 32

  private var dwCommandSeq = 0

  private val mainHandler = Handler(Looper.getMainLooper())

  private var pendingStartupProfilesQueryId: String? = null
  private var pendingReapplyProfilesQueryId: String? = null

  /** Đã chạy [scheduleApplyProfileChain] (từ phản hồi API hoặc fallback). */
  private var startupProfileFlowCompleted = false

  private val fallbackProfileRunnable = Runnable {
    if (startupProfileFlowCompleted) return@Runnable
    Log.w(
      TAG,
      "Fallback tạo profile DataWedge (${DataWedgeConstants.DW_PROFILE_NAME}): không thấy phản hồi GET_PROFILES_LIST đúng chuẩn — gửi CREATE + SET_CONFIG.",
    )
    pendingStartupProfilesQueryId = null
    sendCreateProfile()
    scheduleApplyProfileChain()
    markStartupProfileFlowCompleted()
  }

  fun attachToEngine(messenger: BinaryMessenger) {
    MethodChannel(messenger, ZebraChannels.DATAWEDGE_METHOD).setMethodCallHandler { call, result ->
      when (call.method) {
        "getDiagnostics" -> {
          result.success(buildZebraDiagnosticsMap(activity, actionScanEvent))
        }
        "switchToAppProfile" -> {
          sendSwitchToProfile()
          result.success(null)
        }
        "startScan" -> {
          sendSoftScanTrigger("START_SCANNING")
          result.success(null)
        }
        "stopScan" -> {
          sendSoftScanTrigger("STOP_SCANNING")
          result.success(null)
        }
        "enableDataWedge" -> {
          sendEnableDataWedge(true)
          result.success(null)
        }
        "getActiveProfile" -> {
          sendGetActiveProfile()
          result.success(null)
        }
        "reapplyProfile" -> {
          pendingReapplyProfilesQueryId = sendGetProfilesList()
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }

    EventChannel(messenger, ZebraChannels.BROADCAST_EVENTS).setStreamHandler(
      object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
          eventSink = events
          ensureReceiversRegistered()
          flushPendingToSink()
        }

        override fun onCancel(arguments: Any?) {
          eventSink = null
        }
      },
    )

    ensureReceiversRegistered()

    mainHandler.postDelayed({ sendEnableDataWedge(true) }, 200L)
    mainHandler.postDelayed({ sendRegisterForScannerStatus() }, 350L)
    mainHandler.postDelayed(
      {
        pendingStartupProfilesQueryId = sendGetProfilesList()
        Log.d(TAG, "GET_PROFILES_LIST gửi, COMMAND_IDENTIFIER=$pendingStartupProfilesQueryId")
      },
      DELAY_GET_PROFILES_LIST_MS,
    )
    mainHandler.postDelayed(fallbackProfileRunnable, FALLBACK_PROFILE_SETUP_MS)
  }

  fun processIntentForScan(intent: Intent?) {
    if (intent == null) return
    val hasDataString = intent.getStringExtra("com.symbol.datawedge.data_string")?.isNotEmpty() == true
    val action = intent.action
    val matchOurAction =
      action == actionScanEvent ||
      action == actionScanLegacy ||
      action == DataWedgeConstants.ACTION_SCANRESULT_COMPAT
    if (!hasDataString && !matchOurAction) return

    val payload = HashMap<String, Any?>()
    payload["kind"] = "scan_activity_intent"
    payload["action"] = action ?: "(no action)"
    payload["data"] = intent.dataString
    val ds = intent.getStringExtra("com.symbol.datawedge.data_string")
    if (!ds.isNullOrEmpty()) {
      payload["com.symbol.datawedge.data_string"] = ds
    }
    val extras = intent.extras
    if (extras != null) {
      payload["extras"] = FlutterBundleCodec.extrasToStringMap(extras)
    }
    val resolved = ScanIntentParser.resolveBarcodeString(intent)
    if (!resolved.isNullOrEmpty()) {
      payload["resolvedBarcode"] = resolved
    }
    deliverPayload(payload)
  }

  fun onResume() {
    mainHandler.postDelayed({ sendSwitchToProfile() }, 200L)
  }

  fun dispose() {
    mainHandler.removeCallbacks(fallbackProfileRunnable)
    mainHandler.removeCallbacksAndMessages(null)
    unregisterReceivers()
  }

  private fun deliverScanPayload(intent: Intent, kind: String) {
    val payload = HashMap<String, Any?>()
    payload["kind"] = kind
    payload["action"] = intent.action
    payload["data"] = intent.dataString
    val ds = intent.getStringExtra("com.symbol.datawedge.data_string")
    if (!ds.isNullOrEmpty()) {
      payload["com.symbol.datawedge.data_string"] = ds
    }
    payload["com.symbol.datawedge.source"] = intent.getStringExtra("com.symbol.datawedge.source")
    payload["com.symbol.datawedge.label_type"] = intent.getStringExtra("com.symbol.datawedge.label_type")
    val extras = intent.extras
    if (extras != null) {
      payload["extras"] = FlutterBundleCodec.extrasToStringMap(extras)
    }
    val resolved = ScanIntentParser.resolveBarcodeString(intent)
    if (!resolved.isNullOrEmpty()) {
      payload["resolvedBarcode"] = resolved
    }
    deliverPayload(payload)
  }

  private fun deliverApiResultPayload(intent: Intent) {
    maybeContinueAfterProfilesList(intent)
    val payload = HashMap<String, Any?>()
    payload["kind"] = "datawedge_api_result"
    payload["action"] = intent.action
    payload["COMMAND"] = intent.getStringExtra("COMMAND")
    payload["COMMAND_IDENTIFIER"] = intent.getStringExtra("COMMAND_IDENTIFIER")
    payload["RESULT"] = intent.getStringExtra("RESULT")
    val ri = intent.getBundleExtra("RESULT_INFO")
    if (ri != null) {
      payload["RESULT_INFO"] = FlutterBundleCodec.bundleToStringMap(ri)
    }
    deliverPayload(payload)
  }

  private fun ensureReceiversRegistered() {
    if (dwReceiver != null) return
    dwReceiver =
      object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
          if (intent == null) return
          when (intent.action) {
            DataWedgeConstants.ACTION_RESULT -> deliverApiResultPayload(intent)
            DataWedgeConstants.ACTION_NOTIFICATION -> {
              val payload = HashMap<String, Any?>()
              payload["kind"] = "datawedge_notification"
              payload["action"] = intent.action
              val nb = intent.getBundleExtra("com.symbol.datawedge.api.NOTIFICATION")
              if (nb != null) {
                payload["notification"] = FlutterBundleCodec.bundleToStringMap(nb)
              }
              deliverPayload(payload)
            }
            actionScanEvent, actionScanLegacy, DataWedgeConstants.ACTION_SCANRESULT_COMPAT ->
              deliverScanPayload(intent, "scan_broadcast")
            else -> {
              if (!intent.getStringExtra("com.symbol.datawedge.data_string").isNullOrEmpty()) {
                deliverScanPayload(intent, "scan_broadcast")
              }
            }
          }
        }
      }
    val filter =
      IntentFilter().apply {
        addAction(actionScanEvent)
        addAction(actionScanLegacy)
        addAction(DataWedgeConstants.ACTION_SCANRESULT_COMPAT)
        addAction(DataWedgeConstants.ACTION_RESULT)
        addAction(DataWedgeConstants.ACTION_NOTIFICATION)
        addCategory(Intent.CATEGORY_DEFAULT)
      }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      activity.registerReceiver(dwReceiver, filter, Context.RECEIVER_EXPORTED)
    } else {
      @Suppress("DEPRECATION")
      activity.registerReceiver(dwReceiver, filter)
    }
  }

  private fun deliverPayload(payload: HashMap<String, Any?>) {
    val sink = eventSink
    if (sink != null) {
      activity.runOnUiThread { sink.success(payload) }
    } else {
      synchronized(pendingPayloads) {
        while (pendingPayloads.size >= maxPending) pendingPayloads.removeFirst()
        pendingPayloads.addLast(HashMap(payload))
      }
    }
  }

  private fun flushPendingToSink() {
    val sink = eventSink ?: return
    synchronized(pendingPayloads) {
      while (pendingPayloads.isNotEmpty()) {
        sink.success(pendingPayloads.removeFirst())
      }
    }
  }

  private fun unregisterReceivers() {
    try {
      if (dwReceiver != null) activity.unregisterReceiver(dwReceiver)
    } catch (_: Exception) {
    } finally {
      dwReceiver = null
    }
  }

  private fun sendDwIntent(configure: Intent.() -> Unit): String {
    val cid = "dw_${++dwCommandSeq}"
    val i = Intent(DataWedgeConstants.DW_API_ACTION).apply(configure)
    i.putExtra("SEND_RESULT", "LAST_RESULT")
    i.putExtra("COMMAND_IDENTIFIER", cid)
    i.setPackage(DataWedgeConstants.DW_PACKAGE)
    activity.sendBroadcast(i)
    return cid
  }

  private fun sendEnableDataWedge(enabled: Boolean) {
    sendDwIntent {
      putExtra("com.symbol.datawedge.api.ENABLE_DATAWEDGE", enabled)
    }
  }

  private fun sendCreateProfile() {
    sendDwIntent {
      putExtra("com.symbol.datawedge.api.CREATE_PROFILE", DataWedgeConstants.DW_PROFILE_NAME)
    }
  }

  private fun sendSetConfigSinglePlugin(
    pluginBundle: Bundle,
    configMode: String = "UPDATE",
    includeAppList: Boolean = false,
  ) {
    val main =
      Bundle().apply {
        putString("PROFILE_NAME", DataWedgeConstants.DW_PROFILE_NAME)
        putString("PROFILE_ENABLED", "true")
        putString("CONFIG_MODE", configMode)
        putBundle("PLUGIN_CONFIG", pluginBundle)
        if (includeAppList) {
          putParcelableArray(
            "APP_LIST",
            arrayOf(
              DataWedgePluginBundles.appAssociationBundle(activity.packageName),
            ),
          )
        }
      }
    sendDwIntent {
      putExtra("com.symbol.datawedge.api.SET_CONFIG", main)
    }
  }

  private fun sendSwitchToProfile() {
    sendDwIntent {
      putExtra("com.symbol.datawedge.api.SWITCH_TO_PROFILE", DataWedgeConstants.DW_PROFILE_NAME)
    }
  }

  private fun sendSoftScanTrigger(mode: String) {
    sendDwIntent {
      putExtra("com.symbol.datawedge.api.SOFT_SCAN_TRIGGER", mode)
    }
  }

  private fun sendGetActiveProfile() {
    sendDwIntent {
      putExtra("com.symbol.datawedge.api.GET_ACTIVE_PROFILE", "")
    }
  }

  private fun Intent.dwResultBundle(): Bundle? {
    getBundleExtra("RESULT_INFO")?.let { return it }
    getBundleExtra("com.symbol.datawedge.api.RESULT_INFO")?.let { return it }
    return null
  }

  /** Đọc extra ở root Intent hoặc trong bundle kết quả (tùy bản DataWedge). */
  private fun Intent.getDwStringExtra(key: String): String? {
    getStringExtra(key)?.let { return it }
    return dwResultBundle()?.getString(key)
  }

  private fun extractProfilesList(intent: Intent): List<String> {
    intent.getStringArrayExtra(DataWedgeConstants.RESULT_GET_PROFILES_LIST)?.let { return it.toList() }
    intent.dwResultBundle()?.getStringArray(DataWedgeConstants.RESULT_GET_PROFILES_LIST)?.let { return it.toList() }
    val b = intent.dwResultBundle() ?: return emptyList()
    for (k in b.keySet()) {
      if (k.contains("RESULT_GET_PROFILES_LIST", ignoreCase = true)) {
        @Suppress("DEPRECATION")
        b.getStringArray(k)?.let { return it.toList() }
      }
    }
    return emptyList()
  }

  private fun maybeContinueAfterProfilesList(intent: Intent) {
    val cid = intent.getDwStringExtra("COMMAND_IDENTIFIER") ?: return
    val matchesStartup = cid == pendingStartupProfilesQueryId
    val matchesReapply = cid == pendingReapplyProfilesQueryId
    if (!matchesStartup && !matchesReapply) return

    val cmd = intent.getDwStringExtra("COMMAND")
    val isProfilesList =
      cmd == "GET_PROFILES_LIST" ||
      cmd?.contains("GET_PROFILES", ignoreCase = true) == true ||
      intent.hasExtra(DataWedgeConstants.RESULT_GET_PROFILES_LIST) ||
      intent.dwResultBundle()?.getStringArray(DataWedgeConstants.RESULT_GET_PROFILES_LIST) != null
    if (!isProfilesList) return

    if (matchesStartup) pendingStartupProfilesQueryId = null
    if (matchesReapply) pendingReapplyProfilesQueryId = null

    val result = intent.getDwStringExtra("RESULT")
    val profiles = extractProfilesList(intent)
    val hasOurs = profiles.contains(DataWedgeConstants.DW_PROFILE_NAME)
    val shouldCreate =
      when (result) {
        "SUCCESS" -> !hasOurs
        else -> true
      }

    Log.d(
      TAG,
      "GET_PROFILES_LIST phản hồi: cmd=$cmd result=$result profiles=${profiles.size} hasOurs=$hasOurs shouldCreate=$shouldCreate",
    )

    if (shouldCreate) {
      sendCreateProfile()
    }
    scheduleApplyProfileChain()
    markStartupProfileFlowCompleted()
  }

  private fun markStartupProfileFlowCompleted() {
    if (startupProfileFlowCompleted) return
    startupProfileFlowCompleted = true
    mainHandler.removeCallbacks(fallbackProfileRunnable)
  }

  private fun scheduleApplyProfileChain() {
    mainHandler.postDelayed({
      sendSetConfigSinglePlugin(
        DataWedgePluginBundles.barcodePluginBundle(),
        configMode = "OVERWRITE",
        includeAppList = true,
      )
    }, 400L)
    mainHandler.postDelayed({
      sendSetConfigSinglePlugin(
        DataWedgePluginBundles.intentPluginBundle(actionScanEvent),
        configMode = "UPDATE",
      )
    }, 800L)
    mainHandler.postDelayed({
      sendSetConfigSinglePlugin(DataWedgePluginBundles.keystrokePluginBundle(), configMode = "UPDATE")
    }, 1100L)
    mainHandler.postDelayed({ sendSwitchToProfile() }, 1500L)
    mainHandler.postDelayed({ sendGetActiveProfile() }, 1800L)
  }

  private fun sendGetProfilesList(): String {
    return sendDwIntent {
      putExtra("com.symbol.datawedge.api.GET_PROFILES_LIST", "")
    }
  }

  private fun sendRegisterForScannerStatus() {
    val b =
      Bundle().apply {
        putString("com.symbol.datawedge.api.APPLICATION_NAME", activity.packageName)
        putString("com.symbol.datawedge.api.NOTIFICATION_TYPE", "SCANNER_STATUS")
      }
    sendDwIntent {
      putExtra("com.symbol.datawedge.api.REGISTER_FOR_NOTIFICATION", b)
    }
  }
}
