import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Keystore / signing config ─────────────────────────────────────────────
// Reads from android/key.properties (gitignored).
// Falls back to debug signing if the file doesn't exist (dev / CI without key).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystore = keystorePropertiesFile.exists()
if (hasKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace  = "com.fbt.fbt_hht"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.fbt.fbt_hht"
        minSdk        = flutter.minSdkVersion
        targetSdk     = flutter.targetSdkVersion
        versionCode   = flutter.versionCode
        versionName   = flutter.versionName
    }

    // ── Signing configs ───────────────────────────────────────────
    signingConfigs {
        if (hasKeystore) {
            create("release") {
                keyAlias      = keystoreProperties["keyAlias"]      as String
                keyPassword   = keystoreProperties["keyPassword"]   as String
                storeFile     = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    // ── Build types ───────────────────────────────────────────────
    buildTypes {
        debug {
            // Fast build, no shrinking, debuggable
            isDebuggable   = true
            isMinifyEnabled = false
        }

        release {
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Dev fallback: allows `flutter run --release` without a keystore
                signingConfigs.getByName("debug")
            }

            // R8 full-mode: shrink + obfuscate
            isMinifyEnabled   = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Keyence BT SDK — place the SDK .jar / .aar file in android/app/libs/
    // then uncomment the line below and sync Gradle.
    // implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar", "*.aar"))))

    // AndroidX Core — for FileProvider
    implementation("androidx.core:core-ktx:1.12.0")
}
