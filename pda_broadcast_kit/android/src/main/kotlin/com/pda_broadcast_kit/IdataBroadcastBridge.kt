package com.pda_broadcast_kit

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

/** PDA iData: [android.intent.action.SCANRESULT] → Flutter qua [IDataChannels.BROADCAST_EVENTS]. */
internal class IdataBroadcastBridge(
  private val activity: Activity,
) {
  private var receiver: BroadcastReceiver? = null
  private var eventSink: EventChannel.EventSink? = null

  fun attachToEngine(messenger: BinaryMessenger) {
    EventChannel(messenger, IdataChannels.BROADCAST_EVENTS).setStreamHandler(
      object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
          eventSink = events
          registerReceiverIfNeeded()
        }

        override fun onCancel(arguments: Any?) {
          eventSink = null
          unregisterReceiverIfNeeded()
        }
      },
    )
  }

  fun dispose() {
    unregisterReceiverIfNeeded()
    eventSink = null
  }

  private fun registerReceiverIfNeeded() {
    if (receiver != null) return
    val sink = eventSink ?: return

    receiver = object : BroadcastReceiver() {
      override fun onReceive(context: Context?, intent: Intent?) {
        if (intent == null) return

        val payload = HashMap<String, Any?>()
        payload["action"] = intent.action
        payload["data"] = intent.dataString

        val extras = intent.extras
        if (extras != null) {
          val map = HashMap<String, Any?>()
          for (key in extras.keySet()) {
            map[key] = extras.get(key)?.toString()
          }
          payload["extras"] = map
        }
        sink.success(payload)
      }
    }

    val filter = IntentFilter(IdataChannels.SCAN_RESULT_ACTION)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      activity.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
    } else {
      @Suppress("DEPRECATION")
      activity.registerReceiver(receiver, filter)
    }
  }

  private fun unregisterReceiverIfNeeded() {
    if (receiver == null) return
    try {
      activity.unregisterReceiver(receiver)
    } catch (_: Exception) {
    } finally {
      receiver = null
    }
  }
}

internal object IdataChannels {
  const val BROADCAST_EVENTS = "idata/broadcast_events"
  const val SCAN_RESULT_ACTION = "android.intent.action.SCANRESULT"
}
