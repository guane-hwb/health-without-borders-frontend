# Flutter ProGuard Rules

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# SQFlite & Secure Storage
-keep class com.tekartik.sqflite.** { *; }
-keep class com.it_next.flutter_secure_storage.** { *; }

# Cryptography / Tink / AES
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**