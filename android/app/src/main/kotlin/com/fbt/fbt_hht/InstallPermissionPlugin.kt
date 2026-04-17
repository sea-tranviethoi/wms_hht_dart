package com.fbt.fbt_hht

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * InstallPermissionPlugin
 *
 * Manages the "Install unknown apps" (REQUEST_INSTALL_PACKAGES) permission
 * required for OTA APK installation on Android 8.0+ (API 26+).
 *
 * Flutter counterpart : lib/core/update/app_updater.dart
 *   MethodChannel 'com.fbthht/install_permission'
 *
 * Methods (Flutter → native):
 *   canRequestPackageInstalls → bool
 *       Returns true if the app is allowed to install APKs.
 *       Always true on Android < 8 (API < 26).
 *
 *   openInstallPermissionSettings → void
 *       Opens the system "Install unknown apps" settings page so the
 *       user can grant the permission manually.
 *
 * ── Usage in Dart ─────────────────────────────────────────────────────────
 *   const _ch = MethodChannel('com.fbthht/install_permission');
 *
 *   final allowed = await _ch.invokeMethod<bool>('canRequestPackageInstalls') ?? true;
 *   if (!allowed) {
 *     await _ch.invokeMethod('openInstallPermissionSettings');
 *     // Wait for user to return, then re-check
 *   }
 * ──────────────────────────────────────────────────────────────────────────
 */
class InstallPermissionPlugin(
    private val activity: Activity,
    flutterEngine: FlutterEngine,
) {
    companion object {
        private const val TAG     = "InstallPermissionPlugin"
        private const val CHANNEL = "com.fbthht/install_permission"
    }

    private val channel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        CHANNEL,
    )

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "canRequestPackageInstalls" -> {
                    result.success(canInstall())
                }
                "openInstallPermissionSettings" -> {
                    openSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        Log.d(TAG, "InstallPermissionPlugin initialized")
    }

    // ─── Helpers ──────────────────────────────────────────────────

    /**
     * Returns whether the app currently has permission to install APKs.
     * On Android < 8.0 (API < 26) this is always true (no runtime check needed).
     */
    private fun canInstall(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val allowed = activity.packageManager.canRequestPackageInstalls()
            Log.d(TAG, "canRequestPackageInstalls = $allowed")
            allowed
        } else {
            Log.d(TAG, "Android < 8: install always allowed")
            true
        }
    }

    /**
     * Opens the per-app "Install unknown apps" settings screen.
     * No-op on Android < 8.0.
     */
    private fun openSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d(TAG, "Opening install permission settings")
            val intent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${activity.packageName}"),
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivity(intent)
        }
    }

    fun onDestroy() {
        channel.setMethodCallHandler(null)
    }
}
