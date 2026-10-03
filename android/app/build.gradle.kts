plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val runFlutterTests = tasks.register("runFlutterTests") {
    doFirst {
        val rootDir = project.rootDir.parentFile
        val isWindows = org.gradle.internal.os.OperatingSystem.current().isWindows
        val flutterExecutable = if (isWindows) "flutter.bat" else "flutter"

        println("========================================================================")
        println("Executing 'flutter test' before assembling release build...")
        println("========================================================================")

        val processBuilder = ProcessBuilder(flutterExecutable, "test")
            .directory(rootDir)
            .redirectErrorStream(true)

        val process = processBuilder.start()
        val output = process.inputStream.bufferedReader().use { it.readText() }
        val exitCode = process.waitFor()

        if (exitCode != 0) {
            throw GradleException(
                "\n========================================================================\n" +
                "RELEASE BUILD FAILED: Flutter Tests Failed!\n" +
                "One or more unit or widget tests failed during 'flutter test'.\n\n" +
                "Test Failure Output:\n$output\n" +
                "Please fix all failing tests before building release APK or App Bundle.\n" +
                "========================================================================\n"
            )
        } else {
            println("All Flutter unit & widget tests passed successfully!")
            println("========================================================================")
        }
    }
}

tasks.whenTaskAdded {
    if (name.startsWith("assemble") || name.startsWith("bundle")) {
        dependsOn(runFlutterTests)
    }
}

android {
    namespace = "com.pj.purchase_tracker"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pj.purchase_tracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
