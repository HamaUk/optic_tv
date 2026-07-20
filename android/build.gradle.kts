allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.1")
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)



    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            if (android != null) {
                if (android.namespace.isNullOrEmpty()) {
                    android.namespace = project.group.toString()
                }
                
                // Only bump compileSdk for babstrap to fix the android:attr/lStar error
                if (project.name == "babstrap_settings_screen") {
                    android.compileSdkVersion(34)
                }

                android.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
                (android as? org.gradle.api.plugins.ExtensionAware)?.extensions?.findByName("kotlinOptions")?.let { kotlinOptions ->
                    try {
                        val setJvmTarget = kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
                        setJvmTarget.invoke(kotlinOptions, "17")
                    } catch (e: Exception) {
                        // Fallback or ignore if not available
                    }
                }
            }
        }
        
        // Force Kotlin 17 for all plugins
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
