# Flutter Local Notifications ProGuard Rules

# Keep notification classes
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep Flutter notification plugin classes
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep notification receivers and services
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.app.Service
-keep class * extends android.content.ContentProvider

# Keep notification-related Android classes
-keep class android.app.NotificationManager { *; }
-keep class android.app.NotificationChannel { *; }
-keep class android.app.Notification { *; }
-keep class android.app.Notification$* { *; }
-keep class android.app.PendingIntent { *; }
-keep class android.content.Intent { *; }

# Keep alarm manager classes
-keep class android.app.AlarmManager { *; }
-keep class android.os.PowerManager { *; }
-keep class android.os.PowerManager$WakeLock { *; }

# Keep timezone classes (needed for notification scheduling)
-keep class org.threeten.bp.** { *; }
-keep class java.time.** { *; }

# Keep Gson classes (if used for serialization)
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep shared preferences classes
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$* { *; }

# Keep reflection classes used by notification plugin
-keepclassmembers class * {
    @androidx.annotation.Keep <methods>;
}

-keepclassmembers class * {
    @androidx.annotation.Keep <fields>;
}

# Keep classes with native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep notification sound resources
-keep class **.R$*
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dart VM Service
-keep class dev.flutter.** { *; }

# Keep notification payload classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Additional rules for notification scheduling
-keep class java.util.concurrent.ScheduledExecutorService { *; }
-keep class java.util.concurrent.** { *; }

# Keep boot receiver for notifications
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }

# Google Play Core (for Flutter Play Store split support)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Additional Flutter Play Store rules
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Missing class warnings - ignore these safely
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**