import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 릴리스 서명: android/key.properties 가 있으면 사용, 없으면 debug 키 폴백. 키를 새로 만들지 말 것(CLAUDE.md §1).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keystorePropertiesFile.exists()
if (hasReleaseKey) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.talkverse.english_universe"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.talkverse.english_universe"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 앱내앱(2026-11-08): 영어·토익·토익스피킹·OPIc — 같은 코드, 다른 앱 ID. `flutter build apk --flavor <id> --dart-define=APP=<id>`.
    // id·앱 ID·스킴은 lib/core/app_flavor.dart 와 같아야 한다.
    buildFeatures { resValues = true }   // resValue(app_name) 를 쓰려면 켜야 한다(AGP 8+)
    flavorDimensions += "app"
    productFlavors {
        create("english") {
            dimension = "app"
            applicationId = "com.talkverse.english_universe"
            resValue("string", "app_name", "English Universe")
            manifestPlaceholders["appScheme"] = "talkverse-english"
        }
        create("toeic") {
            dimension = "app"
            applicationId = "com.talkverse.toeic"
            resValue("string", "app_name", "TOEIC Universe")
            manifestPlaceholders["appScheme"] = "talkverse-toeic"
        }
        create("toeic_speaking") {
            dimension = "app"
            applicationId = "com.talkverse.toeic_speaking"
            resValue("string", "app_name", "TOEIC Speaking Universe")
            manifestPlaceholders["appScheme"] = "talkverse-toeicspeaking"
        }
        create("opic") {
            dimension = "app"
            applicationId = "com.talkverse.opic"
            resValue("string", "app_name", "OPIc Universe")
            manifestPlaceholders["appScheme"] = "talkverse-opic"
        }
    }

    signingConfigs {
        if (hasReleaseKey) {
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
            signingConfig = if (hasReleaseKey) {
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
