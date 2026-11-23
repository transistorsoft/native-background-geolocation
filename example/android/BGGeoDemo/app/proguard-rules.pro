# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# (WO-206) The SDK loads HeadlessTask by the name in app.headlessJobService (LocationManager.kt) and creates it
# by reflection, so nothing keeps its constructor or its @Subscribe method: R8 removes both, and every headless
# event is dropped. The rule keeps the name too, because the SDK stores headlessJobService with its config.
-keep class com.transistorsoft.locationmanager.demo.HeadlessTask {
    public <init>();
    @org.greenrobot.eventbus.Subscribe <methods>;
}
