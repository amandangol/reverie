# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# Keep model files
-keep class com.google.mlkit.face.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep custom application class
-keep public class * extends android.app.Application

# Keep custom views
-keep public class * extends android.view.View

# Keep custom activities
-keep public class * extends android.app.Activity

# Keep custom services
-keep public class * extends android.app.Service

# Keep custom receivers
-keep public class * extends android.content.BroadcastReceiver

# Keep custom providers
-keep public class * extends android.content.ContentProvider

# Keep custom back stack
-keep public class * extends android.app.backup.BackupAgent

# Keep custom preferences
-keep public class * extends android.preference.Preference

# Keep custom fragments
-keep public class * extends android.app.Fragment

# Keep custom adapters
-keep public class * extends android.widget.BaseAdapter

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# Keep custom interfaces
-keep interface * extends java.lang.annotation.Annotation

# Keep custom enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep custom serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep custom annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep custom application class
-keep class com.example.reverie.** { *; } 