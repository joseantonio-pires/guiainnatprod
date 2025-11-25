plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "br.embrapa.innat"
    compileSdk = 36  // Android 16 (API 36)
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
        applicationId = "br.embrapa.innat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  // Android 5.0 - Compatibilidade ampla
        targetSdk = 36  // Android 16 - Mais recente com compatibilidade reversa
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Configurações para TensorFlow Lite
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
        
        // Configurações para apps com IA/ML - apenas se necessário
        multiDexEnabled = true
        
        // Suporte a arquivos grandes (modelos TensorFlow)
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
    
    packagingOptions {
        pickFirst("**/libc++_shared.so")
        pickFirst("**/libjsc.so")
    }
    
    // Configuração para modelos TensorFlow Lite grandes
    aaptOptions {
        noCompress("tflite")
        noCompress("lite")
        noCompress("json")
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isDebuggable = true
            applicationIdSuffix = ".debug"
        }
        
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // Disable R8 minification to avoid missing class issues
            // Can be enabled later with proper ProGuard rules
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = false
            
            // ProGuard rules (when minification is enabled)
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Para compatibilidade com apps de IA/ML
    implementation("androidx.multidex:multidex:2.0.1")
}
