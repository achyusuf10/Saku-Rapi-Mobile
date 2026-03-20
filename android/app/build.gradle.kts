// Import necessary Java classes
import java.io.File
import java.io.FileInputStream
import java.util.Properties
import java.text.SimpleDateFormat
import java.util.Date

// Define a function to load properties
fun getProperties(filename: String): Properties {
    val properties = Properties()
    val file = rootProject.file(filename) // or just File(filename) if in the same dir
    if (file.exists()) {
        file.inputStream().use { properties.load(it) }
    } else {
        // Handle the case where the file is missing, e.g., throw an error or log a warning
        println("Warning: $filename not found!")
    }
    return properties
}

val keyProperties = getProperties("key.properties")

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.saku_rapi.com"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.saku_rapi.com"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    signingConfigs{
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String?
            keyPassword = keyProperties["keyPassword"] as String?
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String?
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("release")
        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
            applicationVariants.all {
                val variant = this
                outputs.all {
                    val output = this
                    val project = "MyLifte-"
                    val SEP = "_"
                    val PLUS = "+"
                    val buildType = variant.buildType.name
                    val version = variant.versionName
                    val versionCodeApp = variant.versionCode
                    val date = Date()
                    val formatHour = SimpleDateFormat("HH-mm").format(date)
                    val formattedDate = SimpleDateFormat("dd-MM-yy").format(date)
                    
                    val newApkName = "${project}${version}${PLUS}${versionCodeApp}${SEP}${formattedDate}_at_${formatHour}.apk"
                    (this as? com.android.build.gradle.internal.api.BaseVariantOutputImpl)?.outputFileName = newApkName
                }
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
