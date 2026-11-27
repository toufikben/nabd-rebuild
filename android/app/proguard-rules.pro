# R8 rules for Pulse. The app is pure Dart with platform-channel plugins, so
# there is no app code to keep; these cover what the plugins reflect on.

# Flutter's embedding and the generated plugin registrant.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }

# The home-screen widget provider is instantiated by the OS from the manifest.
-keep class com.nabd.journal.JournalWidgetProvider { *; }
-keep class com.nabd.journal.MainActivity { *; }

# flutter_local_notifications resolves these receivers by class name and
# deserialises the scheduled payload with Gson.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# just_audio / ExoPlayer and the media session helpers are referenced through
# the AndroidX media interfaces.
-keep class com.ryanheise.** { *; }
-dontwarn com.ryanheise.**

# in_app_purchase talks to Play Billing through reflection on the AIDL stubs.
-keep class com.android.billingclient.** { *; }
-keep class com.android.vending.billing.** { *; }
-dontwarn com.android.billingclient.**

# local_auth uses a Fragment and BiometricPrompt callbacks.
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# flutter_secure_storage stores values in the Android keystore.
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# speech_to_text and record bind to their own services.
-keep class com.csdcorp.speech_to_text.** { *; }
-keep class com.llfbandit.record.** { *; }
-dontwarn com.llfbandit.record.**

# Keep the annotation metadata the plugins read at runtime.
-keep @interface *
