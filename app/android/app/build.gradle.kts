plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.whiskertales.whisker_tales"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        resValues = true // game_services_project_id below
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.whiskertales.whisker_tales"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Play Games Services project id (T-023, D-025): set
        // `pgsProjectId=<id>` in android/gradle.properties (Play Console →
        // Play Games Services → Configuration). Empty = no cloud save, the
        // game stays fully offline.
        resValue(
            "string",
            "game_services_project_id",
            (project.findProperty("pgsProjectId") as String?) ?: "",
        )
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // PlayGamesSdk.initialize in MainActivity (the games_services plugin
    // does not initialize the SDK itself)
    implementation("com.google.android.gms:play-services-games-v2:20.1.2")
}
