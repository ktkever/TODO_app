plugins {
    id("com.android.application")
    // 홈스크린 위젯(Glance)용 Compose 컴파일러.
    id("org.jetbrains.kotlin.plugin.compose")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.todo_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.todo_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
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

dependencies {
    // 홈스크린 위젯(Glance) 렌더링.
    implementation("androidx.glance:glance-appwidget:1.1.1")
    // WorkManager 주기적 백그라운드 동기화(5단계).
    implementation("androidx.work:work-runtime-ktx:2.11.2")
    // 백그라운드 동기화용 네이티브 Firestore/Auth 읽기 전용 접근(5단계).
    // BoM 33.1.0+부터 Kotlin 확장이 기본 아티팩트에 통합되어 -ktx 접미사가 없다.
    implementation(platform("com.google.firebase:firebase-bom:34.16.0"))
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-auth")
}

flutter {
    source = "../.."
}
