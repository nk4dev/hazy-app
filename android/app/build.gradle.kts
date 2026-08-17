plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "me.nknighta.apps.hazy"
    compileSdk = flutter.compileSdkVersion
    // Pinned to what several plugins (device_info_plus, receive_sharing_intent,
    // etc) require; NDKs are backward compatible so this covers everything.
    // Matches flutter.ndkVersion as of Flutter 3.47 — if a future `flutter
    // pub upgrade` warns about a higher requirement, bump this to match.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "me.nknighta.apps.hazy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // passkeys_android (a transitive dependency of clerk_flutter, for
        // WebAuthn/passkey sign-in) requires 23 — the highest floor among
        // all plugin manifests as of this writing (checked every
        // build/*/intermediates/merged_manifest/**/AndroidManifest.xml).
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
