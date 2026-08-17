allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Plugin subprojects each pin their own Java sourceCompatibility (varies:
// 1.8, 11, 17...) but several don't pin a matching Kotlin jvmTarget, so it
// silently follows whatever JDK runs Gradle instead — Kotlin then rejects
// the mismatch against its own Java task. Reading AGP's own
// compileOptions.sourceCompatibility back out to "match" it isn't safe
// (it's a lazy Property that throws "not yet finalized" if read during
// configuration), so instead force both sides to the same fixed value
// directly on the tasks, in afterEvaluate so this wins over whatever the
// plugin's own build script already set.
subprojects {
    if (project.name == "app") return@subprojects // app module already pins its own consistent 11/11 target
    // AGP registers its own afterEvaluate (when the android plugin applies,
    // during this subproject's own evaluation) that finalizes
    // JavaCompile.sourceCompatibility from the plugin's `compileOptions` —
    // that runs *after* a plain `afterEvaluate` registered here (root
    // config evaluates before any subproject), so it silently wins over a
    // single afterEvaluate override. Nesting one more afterEvaluate defers
    // ours to the end of the callback queue so it applies last.
    afterEvaluate {
        afterEvaluate {
            tasks.withType<JavaCompile>().configureEach {
                sourceCompatibility = "17"
                targetCompatibility = "17"
            }
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
