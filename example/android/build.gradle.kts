plugins {
    id("com.android.application")
    // Kotlin Gradle plugin is provided by the root project's buildscript classpath.
    // Do NOT specify a version here or Gradle will complain that the plugin is already on the classpath.
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.transistorsoft.tslocationmanager.demo"
    compileSdk = 36

    defaultConfig {
        missingDimensionStrategy("version", "v21")
        applicationId = "com.transistorsoft.tslocationmanager.demo"
        minSdk = 29
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            // Use the debug signing config for quick local installs
            signingConfig = signingConfigs.getByName("debug")

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    implementation(project(":tslocationmanager"))
    implementation("org.greenrobot:eventbus:3.3.1")

    implementation("com.google.android.gms:play-services-maps:19.2.0")
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("androidx.core:core:1.17.0")
    implementation("androidx.appcompat:appcompat:1.7.1")
    implementation("com.google.android.material:material:1.13.0")
    implementation("androidx.constraintlayout:constraintlayout:2.2.1")
    implementation("androidx.navigation:navigation-fragment:2.9.5")
    implementation("androidx.navigation:navigation-ui:2.9.5")
    // Unit tests (local JVM)
    testImplementation("androidx.test:core:1.6.1")

    // Instrumented tests (device/emulator)
    androidTestImplementation("androidx.test:core:1.6.1")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    androidTestImplementation("androidx.test:rules:1.6.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.7.0")
}

// Ensure this app is compilable with Kotlin 1.9.x by preventing Kotlin 2.1.x stdlib
// from being resolved transitively.
configurations.configureEach {
    resolutionStrategy {
        force("org.jetbrains.kotlin:kotlin-stdlib:1.9.25")
        force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.25")
        force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.25")
        force("org.jetbrains.kotlin:kotlin-reflect:1.9.25")
    }
}