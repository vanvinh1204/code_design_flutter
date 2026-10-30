package com.pda_broadcast_kit

import android.os.Bundle

/** Bundle / extra → kiểu Flutter StandardCodec hiểu (String, Map, List). */
internal object FlutterBundleCodec {
  fun extrasToStringMap(extras: Bundle): HashMap<String, Any?> {
    val map = HashMap<String, Any?>()
    for (key in extras.keySet()) {
      map[key] = convertValue(extras.get(key))
    }
    return map
  }

  fun bundleToStringMap(b: Bundle): HashMap<String, Any?> {
    val map = HashMap<String, Any?>()
    for (key in b.keySet()) {
      map[key] = convertValue(b.get(key))
    }
    return map
  }

  fun convertValue(v: Any?): Any? {
    return when (v) {
      null -> null
      is Bundle -> bundleToStringMap(v)
      is ByteArray -> String(v)
      is ArrayList<*> -> v.map { convertValue(it) }
      is Array<*> -> v.map { convertValue(it) }
      is String, is Int, is Long, is Double, is Float, is Boolean -> v
      else -> v.toString()
    }
  }
}
