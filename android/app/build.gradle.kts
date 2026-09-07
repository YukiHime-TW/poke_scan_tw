import java.util.Properties

// 1. 讀取 key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.github.yukihimetw.pokescan"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "io.github.yukihimetw.pokescan"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 2. 設定簽署組態 (必須在 buildTypes 之前)
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            // 3. 指定使用上面定義的簽署組態
            signingConfig = signingConfigs.getByName("release")

            // Kotlin DSL 中，布林值設定要加 "is"
            isMinifyEnabled = false
            isShrinkResources = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // 4. 每次 build 都自動產生 pokescan_<versionName>.apk（不含 versionCode）
    //    - Gradle 原生輸出（outputs/apk/<type>/）直接改名
    //    - assemble 後再複製一份到 flutter 慣用的 outputs/flutter-apk/
    //      （flutter build apk 自己那份仍叫 app-release.apk，不動它）
    applicationVariants.all {
        val variant = this
        outputs.all {
            (this as com.android.build.gradle.internal.api.BaseVariantOutputImpl)
                .outputFileName = "pokescan_${variant.versionName}.apk"
        }
        if (variant.buildType.name == "release") {
            assembleProvider.configure {
                doLast {
                    val apk = variant.outputs.first().outputFile
                    if (apk.exists()) {
                        val flutterApkDir = apk.parentFile.parentFile.parentFile
                            .resolve("flutter-apk")
                        flutterApkDir.mkdirs()
                        apk.copyTo(flutterApkDir.resolve(apk.name), overwrite = true)
                    }
                }
            }
        }
    }
}

flutter {
    source = "../.."
}