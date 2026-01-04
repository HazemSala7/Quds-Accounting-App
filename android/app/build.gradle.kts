// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "quds.merged.sala7"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ REQUIRED for qr_code_scanner (core library desugaring)
        isCoreLibraryDesugaringEnabled = true

        // keep your Java version (you are using 17)
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "quds.merged.sala7"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ REQUIRED for qr_code_scanner (core library desugaring)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
