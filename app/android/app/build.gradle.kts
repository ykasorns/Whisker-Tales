import java.io.FileInputStream
import java.util.Properties

// Release signing (T-030, D-035): android/key.properties (never committed)
// names the upload keystore. Without it, release builds are signed with the
// debug key — fine for testing, refused by Play.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

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
        // Play package name — permanent after the first upload, so confirm it
        // before then (RELEASE_CHECKLIST.md).
        applicationId = "com.whiskertales.whisker_tales"
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
        // AdMob app id (D-033): set `admobAppId=ca-app-pub-…~…` in
        // android/gradle.properties for release. The default is Google's
        // published sample id, which only ever serves test ads.
        resValue(
            "string",
            "admob_app_id",
            (project.findProperty("admobAppId") as String?)
                ?: "ca-app-pub-3940256099942544~3347511713",
        )
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
