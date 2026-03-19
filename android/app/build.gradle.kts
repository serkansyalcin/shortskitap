plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.kitaplig.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    packaging {
        resources {
            excludes += setOf("META-INF/DEPENDENCIES")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.kitaplig.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            isDebuggable = true
        }
    }
}

dependencies {
    // Flutter embedding deferred components (Play Store split install)
    implementation("com.google.android.play:core:1.10.3")

    // MultiDex support when minSdk < 21
    implementation("androidx.multidex:multidex:2.0.1")

    // com.google.crypto.tink.util.KeysDownloader optional deps referenced in release builds
    // Use the Android variant to avoid pulling Apache HttpClient (not available on Android runtime)
    implementation("com.google.http-client:google-http-client-android:1.47.0") {
        exclude(group = "org.apache.httpcomponents", module = "httpclient")
        exclude(group = "org.apache.httpcomponents", module = "httpcore")
    }
    implementation("joda-time:joda-time:2.12.7")
    implementation("org.joda:joda-convert:2.2.3")
}

flutter {
    source = "../.."
}
