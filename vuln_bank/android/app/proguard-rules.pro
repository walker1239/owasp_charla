# [fix/M7] Reglas de ofuscación/reducción para el build release.
# Mantén las clases de Flutter necesarias y elimina logs en release.
-dontwarn io.flutter.**
-keep class io.flutter.** { *; }
-assumenosideeffects class android.util.Log { *; }
