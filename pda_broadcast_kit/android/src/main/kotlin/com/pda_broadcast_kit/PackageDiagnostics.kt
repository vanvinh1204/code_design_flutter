package com.pda_broadcast_kit

import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import java.security.MessageDigest

/** Thông tin build / DataWedge cho màn diagnostics Flutter. */
internal fun buildZebraDiagnosticsMap(context: Context, scanIntentAction: String): Map<String, Any?> {
  val map = HashMap<String, Any?>()
  map["ourPackageName"] = context.packageName
  map["scanIntentActionFlutterDatawedgeStyle"] = scanIntentAction
  map["appSignatureSha1"] = getSigningSha1Hex(context) ?: "unknown"
  map["datawedgePackage"] = DataWedgeConstants.DW_PACKAGE
  try {
    val info =
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        context.packageManager.getPackageInfo(
          DataWedgeConstants.DW_PACKAGE,
          PackageManager.PackageInfoFlags.of(0),
        )
      } else {
        @Suppress("DEPRECATION")
        context.packageManager.getPackageInfo(DataWedgeConstants.DW_PACKAGE, 0)
      }
    map["datawedgeInstalled"] = true
    map["datawedgeVersionName"] = info.versionName
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      map["datawedgeVersionCode"] = info.longVersionCode
    } else {
      @Suppress("DEPRECATION")
      map["datawedgeVersionCode"] = info.versionCode.toLong()
    }
  } catch (_: PackageManager.NameNotFoundException) {
    map["datawedgeInstalled"] = false
  }
  return map
}

/** SHA-1 cert (hex, upper case) — DataWedge “Component information”. */
private fun getSigningSha1Hex(context: Context): String? {
  try {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
      val pkg = context.packageManager.getPackageInfo(context.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
      val si = pkg.signingInfo ?: return legacySignaturesSha1(context)
      val sig: Signature =
        if (si.hasMultipleSigners()) {
          si.apkContentsSigners[0]
        } else {
          si.signingCertificateHistory[0]
        }
      return sha1Hex(sig.toByteArray())
    }
  } catch (_: Exception) {
  }
  return legacySignaturesSha1(context)
}

@Suppress("DEPRECATION")
private fun legacySignaturesSha1(context: Context): String? {
  return try {
    val pkg = context.packageManager.getPackageInfo(context.packageName, PackageManager.GET_SIGNATURES)
    val sig = pkg.signatures?.firstOrNull() ?: return null
    sha1Hex(sig.toByteArray())
  } catch (_: Exception) {
    null
  }
}

private fun sha1Hex(bytes: ByteArray): String {
  val md = MessageDigest.getInstance("SHA-1")
  val digest = md.digest(bytes)
  val sb = StringBuilder(digest.size * 2)
  for (b in digest) {
    sb.append(String.format("%02X", b))
  }
  return sb.toString()
}
