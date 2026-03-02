# Ignore all optional ML Kit language packages
-dontwarn com.google.mlkit.**
-keep class com.google.mlkit.** { *; }

# Ignore TensorFlow Lite GPU delegate classes
-dontwarn org.tensorflow.lite.**
-keep class org.tensorflow.lite.** { *; }