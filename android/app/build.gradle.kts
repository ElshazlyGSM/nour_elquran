import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val hasReleaseSigning =
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all {
        !keystoreProperties.getProperty(it).isNullOrBlank()
    }

android {
    namespace = "com.elshazly.noorquran.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.elshazly.noorquran.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    packagingOptions {
        resources {
            excludes += "assets/flutter_assets/packages/quran_library/assets/fonts/quran_fonts_qfc4/**"
            excludes += "**/quran_fonts_qfc4/**"
            excludes += "**/QCF4_tajweed_*.ttf.gz"
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

afterEvaluate {
    fun registerFlutterApkMirrorTask(taskName: String, variantName: String) {
        tasks.matching { it.name == taskName }.configureEach {
            doLast {
                val sourceDir = file("$buildDir/outputs/apk/$variantName")
                val flutterOutputDir = rootProject.projectDir.parentFile.resolve(
                    "build/app/outputs/flutter-apk",
                )
                flutterOutputDir.mkdirs()

                val defaultApk = sourceDir.resolve("app-$variantName.apk")
                if (defaultApk.exists()) {
                    copy {
                        from(defaultApk)
                        into(flutterOutputDir)
                        rename { "app-$variantName.apk" }
                    }
                    return@doLast
                }

                sourceDir
                    .listFiles()
                    ?.filter { file ->
                        file.isFile &&
                            file.extension.equals("apk", ignoreCase = true) &&
                            file.name.endsWith("-$variantName.apk")
                    }
                    ?.forEach { splitApk ->
                        copy {
                            from(splitApk)
                            into(flutterOutputDir)
                        }
                    }
            }
        }
    }

    fun registerFlutterBundleMirrorTask(taskName: String, variantName: String) {
        tasks.matching { it.name == taskName }.configureEach {
            doLast {
                val sourceBundle = file("$buildDir/outputs/bundle/$variantName/app-$variantName.aab")
                if (!sourceBundle.exists()) {
                    return@doLast
                }

                val flutterOutputDir = rootProject.projectDir.parentFile.resolve(
                    "build/app/outputs/bundle/$variantName",
                )
                flutterOutputDir.mkdirs()

                copy {
                    from(sourceBundle)
                    into(flutterOutputDir)
                    rename { "app-$variantName.aab" }
                }
            }
        }
    }

    registerFlutterApkMirrorTask("assembleDebug", "debug")
    registerFlutterApkMirrorTask("assembleRelease", "release")
    registerFlutterBundleMirrorTask("bundleRelease", "release")

    // Ensure the huge embedded QCF4 font assets are removed from release assets.
    tasks.matching { it.name == "mergeReleaseAssets" }.configureEach {
        doFirst {
            val flutterAssetsDir = file(
                "$buildDir/intermediates/flutter/release/flutter_assets/" +
                    "packages/quran_library/assets/fonts/quran_fonts_qfc4",
            )
            val mergedAssetsDir = file(
                "$buildDir/intermediates/assets/release/mergeReleaseAssets/" +
                    "flutter_assets/packages/quran_library/assets/fonts/quran_fonts_qfc4",
            )
            if (flutterAssetsDir.exists()) {
                flutterAssetsDir.deleteRecursively()
            }
            if (mergedAssetsDir.exists()) {
                mergedAssetsDir.deleteRecursively()
            }
        }
    }
}

flutter {
    source = "../.."
}
