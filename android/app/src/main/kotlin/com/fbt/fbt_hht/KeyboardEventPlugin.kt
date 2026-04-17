package com.fbt.fbt_hht

import android.app.Activity
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * KeyboardEventPlugin
 *
 * Intercepts Keyence hardware button key events and forwards them to
 * Flutter's KeyboardEventBus via a MethodChannel.
 *
 * Flutter counterpart : lib/core/hardware/native_keyboard_channel.dart
 *   MethodChannel 'com.fbthht/keyboard_events'
 *   → Flutter calls setMethodCallHandler and receives 'onKeyDown'
 *
 * ── Key code mapping (from key_codes.dart) ────────────────────────────────
 *  8   = Warehouse Receipt (入荷)
 *  9   = Putaway (棚上げ)
 *  10  = Picking (ピッキング)
 *  11  = Bundle (事前セット)
 *  12  = Bin Movement (棚移動)
 *  13  = Bin Audit (棚卸)
 *  14  = Logout (ログアウト)
 *  103 = Scan trigger (left side button)
 *  104 = Scan trigger (right side button)
 * ──────────────────────────────────────────────────────────────────────────
 *
 * These key codes are sent by the Keyence BT-H / BT-W series side buttons
 * as standard Android KeyEvents. MainActivity.onKeyDown intercepts them
 * before they reach the Flutter framework and calls handleKeyDown().
 */
class KeyboardEventPlugin(
    private val activity: Activity,
    flutterEngine: FlutterEngine,
) {
    companion object {
        private const val TAG     = "KeyboardEventPlugin"
        private const val CHANNEL = "com.fbthht/keyboard_events"

        /** All hardware key codes that should be forwarded to Flutter. */
        private val HANDLED_KEY_CODES = setOf(
            8, 9, 10, 11, 12, 13, 14,   // module navigation buttons
            103, 104,                    // scan trigger (left / right)
        )
    }

    private val channel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        CHANNEL,
    )

    init {
        // Native → Flutter direction only; no inbound handler needed here.
        // Flutter side sets its own setMethodCallHandler to receive events.
        Log.d(TAG, "KeyboardEventPlugin initialized")
    }

    /**
     * Called from [MainActivity.onKeyDown].
     *
     * @return true if the keyCode was handled (consumed), false otherwise.
     */
    fun handleKeyDown(keyCode: Int): Boolean {
        if (keyCode !in HANDLED_KEY_CODES) return false

        Log.d(TAG, "Hardware key pressed: $keyCode")
        activity.runOnUiThread {
            channel.invokeMethod("onKeyDown", keyCode)
        }
        return true // consumed — prevents default Android back/home behavior
    }

    fun onDestroy() {
        channel.setMethodCallHandler(null)
    }
}
