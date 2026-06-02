# Keep Google Maps
-keep class com.google.android.gms.** { *; }
-keep class com.google.maps.** { *; }

# Keep Socket.IO client
-keep class io.socket.** { *; }
-keep class okhttp3.** { *; }

# Keep Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep app model classes
-keep class com.kerja.serabutan.** { *; }

# Prevent removing unused code that's needed at runtime
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
