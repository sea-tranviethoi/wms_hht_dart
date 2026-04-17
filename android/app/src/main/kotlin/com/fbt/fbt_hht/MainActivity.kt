package com.fbt.fbt_hht

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * MainActivity
 *
 * Hosts three native platform-channel plugins:
 *  • ScanManagerPlugin       — Keyence BT barcode scanner SDK
 *  • KeyboardEventPlugin     — hardware side-button → Flutter KeyboardEventBus
 *  • InstallPermissionPlugin — OTA APK install permission (Android 8+)
 *
 * All channel names are prefixed with 'com.fbthht/' to match the
 * Dart constants in lib/core/hardware/ and lib/core/update/.
 */
class MainActivity : FlutterActivity() {

    private lateinit var scanManagerPlugin:       ScanManagerPlugin
    private lateinit var keyboardEventPlugin:     KeyboardEventPlugin
    private lateinit var installPermissionPlugin: InstallPermissionPlugin

    // ─── Flutter engine setup ─────────────────────────────────────

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        scanManagerPlugin       = ScanManagerPlugin(this, flutterEngine)
        keyboardEventPlugin     = KeyboardEventPlugin(this, flutterEngine)
        installPermissionPlugin = InstallPermissionPlugin(this, flutterEngine)
    }

    // ─── Hardware key forwarding ──────────────────────────────────

    /**
     * Intercepts Keyence side-button key events (keyCodes 8–14, 103–104)
     * and forwards them to Flutter's KeyboardEventBus via MethodChannel.
     * Returns true (consumed) so Android doesn't process them further.
     */
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (::keyboardEventPlugin.isInitialized &&
            keyboardEventPlugin.handleKeyDown(keyCode)
        ) {
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    // ─── Activity lifecycle → scanner ─────────────────────────────

    override fun onResume() {
        super.onResume()
        if (::scanManagerPlugin.isInitialized) scanManagerPlugin.onResume()
    }

    override fun onPause() {
        super.onPause()
        if (::scanManagerPlugin.isInitialized) scanManagerPlugin.onPause()
    }

    override fun onDestroy() {
        if (::scanManagerPlugin.isInitialized)       scanManagerPlugin.onDestroy()
        if (::keyboardEventPlugin.isInitialized)     keyboardEventPlugin.onDestroy()
        if (::installPermissionPlugin.isInitialized) installPermissionPlugin.onDestroy()
        super.onDestroy()
    }
}
