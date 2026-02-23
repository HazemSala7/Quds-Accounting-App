// android/build.gradle.kts

import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

import com.android.build.api.variant.LibraryAndroidComponentsExtension
import com.android.build.api.variant.ApplicationAndroidComponentsExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// --- Keep your custom buildDir logic ---
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Flutter template ordering
subprojects {
    project.evaluationDependsOn(":app")
}

/**
 * ✅ FIX (Variant API only):
 * Force compileSdk=34 for all Android modules (especially plugin libraries)
 * without touching the old DSL (which causes: "It is too late to set compileSdk").
 * Also add namespace to Android Library plugins that require it.
 */
subprojects {

    // Android Library modules (Flutter plugins)
    plugins.withId("com.android.library") {
        extensions.configure<LibraryAndroidComponentsExtension>("androidComponents") {
            finalizeDsl { dsl ->
                dsl.compileSdk = 34
                // Add namespace if not already set
                if (dsl.namespace == null) {
                    dsl.namespace = "io.flutter.plugins.${project.name}"
                }
            }
            // Strip package attribute before manifest processing
            beforeVariants { variantBuilder ->
                // This ensures the namespace is used instead of package attribute
            }
        }
    }

    // Android Application modules (just in case)
    plugins.withId("com.android.application") {
        extensions.configure<ApplicationAndroidComponentsExtension>("androidComponents") {
            finalizeDsl { dsl ->
                dsl.compileSdk = 34
            }
        }
    }
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ✅ Strip package attribute from plugin AndroidManifest.xml files to avoid conflicts with namespace
gradle.afterProject {
    if (project.plugins.hasPlugin("com.android.library")) {
        val manifestFile = project.file("src/main/AndroidManifest.xml")
        if (manifestFile.exists()) {
            var content = manifestFile.readText()
            // Remove package attribute from manifest tag
            val originalContent = content
            content = content.replace(Regex("""package="[^"]*"\s*"""), "")
            if (originalContent != content) {
                manifestFile.writeText(content)
                println("Stripped package attribute from ${manifestFile.absolutePath}")
            }
        }
    }
}
