# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Google Fonts
-keep class com.google.android.gms.** { *; }

# Keep SharedPreferences
-keep class androidx.preference.** { *; }

# Keep Vibration plugin
-keep class com.benjaminabel.vibration.** { *; }

# Keep AudioPlayers plugin
-keep class xyz.luan.audioplayers.** { *; }

# General optimizations
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
