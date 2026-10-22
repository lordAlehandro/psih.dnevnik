# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Keep your application classes
-keep class com.example.** { *; }

# Keep Lottie animations
-keep class com.airbnb.lottie.** { *; }

# Keep SharedPreferences
-keep class androidx.preference.** { *; }

# Keep TableCalendar
-keep class com.alee.laf.** { *; }

# Keep ImagePicker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep Intl
-keep class com.google.i18n.** { *; }

# Keep any custom classes that might be used in reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepattributes Exceptions

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep R8 rules
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleAnnotations, RuntimeInvisibleParameterAnnotations
-keepattributes AnnotationDefault
-keepattributes Signature
-keepattributes Exceptions
-keepattributes *Annotation*

# Keep R8 full mode optimizations
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose

# Keep Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# Keep Kotlin Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# Keep Room
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-keep @androidx.room.Dao interface *

# Keep WorkManager
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker

# Keep Biometric
-keep class androidx.biometric.** { *; }

# Keep Security
-keep class androidx.security.** { *; }

# Keep Window
-keep class androidx.window.** { *; }

# Keep Material Design
-keep class com.google.android.material.** { *; }

# Keep Lifecycle
-keep class androidx.lifecycle.** { *; }

# Keep Navigation
-keep class androidx.navigation.** { *; }

# Keep RecyclerView
-keep class androidx.recyclerview.** { *; }

# Keep CardView
-keep class androidx.cardview.** { *; }

# Keep SwipeRefreshLayout
-keep class androidx.swiperefreshlayout.** { *; }

# Keep ConstraintLayout
-keep class androidx.constraintlayout.** { *; }

# Keep AppCompat
-keep class androidx.appcompat.** { *; }

# Keep Core KTX
-keep class androidx.core.** { *; }

# Keep WorkManager
-keep class androidx.work.** { *; }

# Keep Room
-keep class androidx.room.** { *; }

# Keep Firebase Analytics
-keep class com.google.firebase.analytics.** { *; }

# Keep Firebase Crashlytics
-keep class com.google.firebase.crashlytics.** { *; }

# Keep Firebase Performance
-keep class com.google.firebase.perf.** { *; }

# Keep Google Play Services
-keep class com.google.android.gms.** { *; }

# Keep Play Core
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; } 