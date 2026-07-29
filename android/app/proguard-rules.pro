# Keep rules for R8 full-mode shrinking.
# Flutter + its plugins ship their own consumer rules; these are conservative
# safety nets so reflection-based paths aren't stripped.

# --- Flutter engine / embedding ---
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# --- Play Core (Flutter deferred components; not used here) ---
-dontwarn com.google.android.play.core.**

# --- Firebase / Google Play services ---
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# --- Keep generic/annotation metadata used by serializers & reflection ---
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
