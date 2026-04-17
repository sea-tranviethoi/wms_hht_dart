package com.fbt.fbt_hht

import android.app.Activity
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// ─── Keyence BT SDK — add jar/aar to android/app/libs/ and uncomment ──────
// import com.keyence.android.BarcodeReader
// import com.keyence.android.ScanManager
// import com.keyence.android.ReadListener

/**
 * ScanManagerPlugin
 *
 * Bridges Flutter ↔ Keyence BT barcode scanner SDK.
 *
 * Flutter counterpart : lib/core/hardware/keyence_scanner.dart
 *
 * MethodChannel  'com.fbthht/keyence_scanner'
 *   → createScanManager   : initialize SDK ScanManager
 *   → startReadControl    : begin scanning (activates trigger button)
 *   → stopReadControl     : pause scanning
 *   → releaseScanManager  : release SDK resources
 *
 * EventChannel   'com.fbthht/keyence_scanner_events'
 *   ← (String)   : every barcode read is pushed as a plain string
 *
 * ── Integration steps (production) ────────────────────────────────────────
 *  1. Copy the Keyence BT SDK jar (e.g. BarcodeReader.jar) into
 *     android/app/libs/
 *  2. Uncomment the SDK imports above and the SDK calls below
 *  3. Uncomment the fileTree dependency in build.gradle.kts
 * ──────────────────────────────────────────────────────────────────────────
 */
class ScanManagerPlugin(
    private val activity: Activity,
    flutterEngine: FlutterEngine,
) {
    companion object {
        private const val TAG = "ScanManagerPlugin"
        private const val METHOD_CHANNEL = "com.fbthht/keyence_scanner"
        private const val EVENT_CHANNEL  = "com.fbthht/keyence_scanner_events"
    }

    private val methodChannel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        METHOD_CHANNEL,
    )
    private val eventChannel = EventChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        EVENT_CHANNEL,
    )

    private var eventSink: EventChannel.EventSink? = null
    // private var scanManager: ScanManager? = null   // uncomment with SDK

    // ─── Init ─────────────────────────────────────────────────────

    init {
        // EventChannel: Flutter listens for scan results
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                eventSink = sink
                Log.d(TAG, "EventChannel: Flutter listening")
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
                Log.d(TAG, "EventChannel: cancelled")
            }
        })

        // MethodChannel: Flutter → native commands
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "createScanManager"  -> { createScanManager(); result.success(null) }
                "startReadControl"   -> { startReadControl();  result.success(null) }
                "stopReadControl"    -> { stopReadControl();   result.success(null) }
                "releaseScanManager" -> { releaseScanManager();result.success(null) }
                else                 -> result.notImplemented()
            }
        }
    }

    // ─── Lifecycle (called from MainActivity) ─────────────────────

    fun onResume() {
        // scanManager?.startRead()
        Log.d(TAG, "onResume")
    }

    fun onPause() {
        // scanManager?.stopRead()
        Log.d(TAG, "onPause")
    }

    fun onDestroy() {
        releaseScanManager()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        Log.d(TAG, "onDestroy — resources released")
    }

    // ─── SDK Methods ──────────────────────────────────────────────

    private fun createScanManager() {
        Log.d(TAG, "createScanManager()")
        // ── Keyence BT SDK (uncomment after adding jar) ────────────
        // val reader = BarcodeReader.getInstance()
        // scanManager = reader.getNewScanManager(activity)
        // scanManager?.setReadListener(ReadListener { readString, _ ->
        //     pushScanResult(readString)
        // })
        // ──────────────────────────────────────────────────────────
    }

    private fun startReadControl() {
        Log.d(TAG, "startReadControl()")
        // scanManager?.startRead()
    }

    private fun stopReadControl() {
        Log.d(TAG, "stopReadControl()")
        // scanManager?.stopRead()
    }

    private fun releaseScanManager() {
        Log.d(TAG, "releaseScanManager()")
        // scanManager?.release()
        // scanManager = null
    }

    // ─── Push result to Flutter ───────────────────────────────────

    /** Send a barcode string to the Flutter EventChannel stream. */
    fun pushScanResult(value: String) {
        activity.runOnUiThread {
            eventSink?.success(value)
        }
    }
}
