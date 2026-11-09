import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key password (store and key share it). Never written to disk: it comes
// from the environment, asked in the terminal by `make appbundle`.
val uploadKeyPasswordEnv = "MEUTEMPO_UPLOAD_KEY_PASSWORD"

// Release signing lives outside the repo (docs/tecnico-time-control.md 6.3).
// key.properties holds only keyAlias and storeFile.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val uploadKeyPassword: String? = System.getenv(uploadKeyPasswordEnv)?.takeIf { it.isNotEmpty() }
val hasReleaseKey = keystorePropertiesFile.exists()
val canSignRelease = hasReleaseKey && uploadKeyPassword != null

android {
    namespace = "br.com.tekton.meutempo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications needs core library desugaring.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.tekton.meutempo"
        // Android 12 (API 31): docs/tecnico-time-control.md 7.1.
        minSdk = 31
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (canSignRelease) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = uploadKeyPassword
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = uploadKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // Without key.properties (another machine) falls back to debug signing.
            // With key.properties but no password, preReleaseBuild fails (below).
            signingConfig = if (canSignRelease) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

// Fails only release builds, so debug runs keep working without the password.
tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    // Locals copied here: the configuration cache cannot serialize script references.
    val missingPassword = hasReleaseKey && uploadKeyPassword == null
    val message = "Defina $uploadKeyPasswordEnv ou use make appbundle."
    doFirst {
        if (missingPassword) throw GradleException(message)
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
