# ─────────────────────────────────────────────────────────────────────────────
# ProGuard / R8 rules for fbt_hht
# Applied in release builds (isMinifyEnabled = true)
# ─────────────────────────────────────────────────────────────────────────────

# ── Flutter engine ────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ── App entry point ───────────────────────────────────────────────────────────
-keep class com.fbt.fbt_hht.** { *; }

# ── Keyence BT SDK ────────────────────────────────────────────────────────────
# Uncomment and adjust when the SDK jar/aar is added to libs/
# -keep class com.keyence.** { *; }
# -dontwarn com.keyence.**

# ── Dio / OkHttp / Retrofit ───────────────────────────────────────────────────
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ── Gson / JSON serialisation ─────────────────────────────────────────────────
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
# Keep data classes used in JSON deserialization
-keep class * implements com.google.gson.TypeAdapterFactory { *; }
-keep class * implements com.google.gson.JsonSerializer { *; }
-keep class * implements com.google.gson.JsonDeserializer { *; }

# ── Crypto / Encryption ───────────────────────────────────────────────────────
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**
-keep class javax.crypto.** { *; }

# ── Flutter Secure Storage ────────────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# ── Mobile Scanner (ZXing / ML Kit) ──────────────────────────────────────────
-keep class dev.steenbakker.mobile_scanner.** { *; }
-dontwarn dev.steenbakker.mobile_scanner.**
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ── Camera / Image Picker ─────────────────────────────────────────────────────
-keep class io.flutter.plugins.camerax.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.camerax.**

# ── Open File ─────────────────────────────────────────────────────────────────
-keep class com.crazecoder.openfile.** { *; }
-dontwarn com.crazecoder.openfile.**

# ── Permission Handler ────────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ── Shared Preferences / SQLite ───────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# ── Audio Players ─────────────────────────────────────────────────────────────
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# ── Connectivity Plus ─────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**

# ── Package / Device Info Plus ────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-dontwarn dev.fluttercommunity.plus.**

# ── AndroidX ─────────────────────────────────────────────────────────────────
-keep class androidx.** { *; }
-dontwarn androidx.**
-keep class android.support.** { *; }
-dontwarn android.support.**

# ── Keep native method names ──────────────────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

# ── Keep Parcelable ───────────────────────────────────────────────────────────
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# ── Keep enums ────────────────────────────────────────────────────────────────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ── Suppress common warnings ──────────────────────────────────────────────────
-dontwarn java.lang.invoke.**
-dontwarn sun.misc.**
-dontwarn javax.annotation.**
