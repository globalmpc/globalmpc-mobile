import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing material is referenced, never committed: android/key.properties
// names the keystore and holds its passwords, and both are gitignored. See
// android/key.properties.example for the expected keys.
//
// When the file is absent (a fresh clone, CI without secrets, any local debug
// work) the release build falls back to the debug key exactly as before, so
// nothing breaks — but it warns, because a debug-signed artifact must never be
// mistaken for a shippable one. A debug key is a publicly known key: anything
// signed with it can be replaced on-device by a build anyone can produce.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasReleaseKeystore) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

// Warn only when a release artifact is actually being produced, so day-to-day
// debug builds stay quiet.
if (!hasReleaseKeystore &&
    gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
) {
    logger.warn(
        "WARNING: android/key.properties not found — signing this RELEASE " +
            "build with the DEBUG key. The debug key is publicly known, so " +
            "this artifact must not be distributed. " +
            "See android/key.properties.example."
    )
}

android {
    namespace = "tech.globalmpc.mpc_mining_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "tech.globalmpc.mpc_mining_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
