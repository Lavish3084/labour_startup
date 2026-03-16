# ProGuard rules for the Labour app

# Razorpay rules
-keepattributes *Annotation*
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keep class com.razorpay.** {*;}
-dontwarn com.razorpay.**

# Flutter and common rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase rules (common if used)
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Play Core rules (for Flutter deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
