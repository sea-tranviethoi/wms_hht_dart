allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Flutter plugins (device_info_plus, audioplayers_android, camera_android_camerax,
// etc.) ship their own build.gradle still targeting Java 8, which javac now
// flags as obsolete on every build. Their source lives in the Pub cache and
// gets overwritten on `flutter pub get`, so it can't be patched directly —
// force every Android module to compile against Java 11 (matching app's own
// compileOptions) from here instead.
//
// Must be registered BEFORE evaluationDependsOn(":app") below: that call
// forces immediate evaluation of whichever subproject it's called for, so if
// this afterEvaluate block were registered afterwards, some subprojects would
// already be evaluated by the time it runs, and afterEvaluate throws on an
// already-evaluated project.
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_11
                targetCompatibility = JavaVersion.VERSION_11
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
