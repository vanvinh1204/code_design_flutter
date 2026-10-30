package com.pda_broadcast_kit

import android.app.Activity
import android.app.Application
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** Đăng ký Zebra DataWedge + iData SCANRESULT; khớp tên kênh Dart [PdaBroadcastChannels]. */
class PdaBroadcastKitPlugin :
  FlutterPlugin,
  ActivityAware {
  private var messenger: io.flutter.plugin.common.BinaryMessenger? = null
  private var boundActivity: Activity? = null
  private var application: Application? = null

  private var zebraBridge: DataWedgeBridge? = null
  private var idataBridge: IdataBroadcastBridge? = null

  private val lifecycleCallbacks: Application.ActivityLifecycleCallbacks =
    object : Application.ActivityLifecycleCallbacks {
      override fun onActivityCreated(activity: Activity, savedInstanceState: android.os.Bundle?) {}

      override fun onActivityStarted(activity: Activity) {}

      override fun onActivityResumed(activity: Activity) {
        if (activity === boundActivity) {
          zebraBridge?.onResume()
          zebraBridge?.processIntentForScan(activity.intent)
        }
      }

      override fun onActivityPaused(activity: Activity) {}

      override fun onActivityStopped(activity: Activity) {}

      override fun onActivitySaveInstanceState(activity: Activity, outState: android.os.Bundle) {}

      override fun onActivityDestroyed(activity: Activity) {}
    }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    messenger = binding.binaryMessenger
    tryAttachBridges()
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    detachBridges()
    messenger = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    boundActivity = binding.activity
    application = binding.activity.application as? Application
    application?.registerActivityLifecycleCallbacks(lifecycleCallbacks)

    binding.addOnNewIntentListener { intent: Intent ->
      zebraBridge?.processIntentForScan(intent)
      false
    }

    tryAttachBridges()
    zebraBridge?.processIntentForScan(binding.activity.intent)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    application?.unregisterActivityLifecycleCallbacks(lifecycleCallbacks)
    application = null
    boundActivity = null
    detachBridges()
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    boundActivity = binding.activity
    application = binding.activity.application as? Application
    application?.registerActivityLifecycleCallbacks(lifecycleCallbacks)
    binding.addOnNewIntentListener { intent: Intent ->
      zebraBridge?.processIntentForScan(intent)
      false
    }
    tryAttachBridges()
    zebraBridge?.processIntentForScan(binding.activity.intent)
  }

  override fun onDetachedFromActivity() {
    application?.unregisterActivityLifecycleCallbacks(lifecycleCallbacks)
    application = null
    boundActivity = null
    detachBridges()
  }

  private fun tryAttachBridges() {
    val m = messenger ?: return
    val act = boundActivity ?: return
    if (zebraBridge == null) {
      zebraBridge = DataWedgeBridge(act).also { it.attachToEngine(m) }
    }
    if (idataBridge == null) {
      idataBridge = IdataBroadcastBridge(act).also { it.attachToEngine(m) }
    }
  }

  private fun detachBridges() {
    zebraBridge?.dispose()
    zebraBridge = null
    idataBridge?.dispose()
    idataBridge = null
  }
}
