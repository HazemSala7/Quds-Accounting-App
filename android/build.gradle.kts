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
 */
subprojects {

    // Android Library modules (Flutter plugins)
    plugins.withId("com.android.library") {
        extensions.configure<LibraryAndroidComponentsExtension>("androidComponents") {
            finalizeDsl { dsl ->
                dsl.compileSdk = 34
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
