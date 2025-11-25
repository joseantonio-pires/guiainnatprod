# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# TensorFlow Lite rules
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.delegates.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }

# Keep GPU delegate factory and options
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegate { *; }

# Keep delegate interfaces
-keep interface org.tensorflow.lite.Delegate { *; }
-keep class * implements org.tensorflow.lite.Delegate { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Don't warn about missing GPU delegate classes
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options
-dontwarn org.tensorflow.lite.gpu.**

# Keep Flutter plugin classes
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Keep tflite_flutter plugin classes
-keep class sq.flutter.tflite.** { *; }

# Don't warn about missing Google Play Core classes (they are optional)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Don't warn about missing Flutter Play Store classes (they are optional)
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep classes that might be referenced via reflection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Don't obfuscate classes that might be used by plugins
-keep class androidx.** { *; }
-dontwarn androidx.**

# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }

# Additional rules for common Flutter plugins
-keep class com.example.** { *; }