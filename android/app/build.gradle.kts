plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.quran_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.quran_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystoreFile = file("upload-keystore.jks")
            val keystorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            val keyAliasName = System.getenv("ANDROID_KEY_ALIAS")
            val keyPasswordVal = System.getenv("ANDROID_KEY_PASSWORD")

            if (keystoreFile.exists() && !keystorePassword.isNullOrEmpty() && !keyAliasName.isNullOrEmpty() && !keyPasswordVal.isNullOrEmpty()) {
                storeFile = keystoreFile
                storePassword = keystorePassword
                keyAlias = keyAliasName
                keyPassword = keyPasswordVal
            }
        }
        getByName("debug") {
            val projectDebugKeystore = file("debug.keystore")
            if (projectDebugKeystore.exists()) {
                storeFile = projectDebugKeystore
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    buildTypes {
        release {
            val keystoreFile = file("upload-keystore.jks")
            val keystorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            val keyAliasName = System.getenv("ANDROID_KEY_ALIAS")
            val keyPasswordVal = System.getenv("ANDROID_KEY_PASSWORD")

            if (keystoreFile.exists() && !keystorePassword.isNullOrEmpty() && !keyAliasName.isNullOrEmpty() && !keyPasswordVal.isNullOrEmpty()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
