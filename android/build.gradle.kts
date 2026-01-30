allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Fix para paquetes que no tienen namespace definido (como flutter_bluetooth_serial)
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExtension = project.extensions.findByName("android")
            if (androidExtension != null) {
                val android = androidExtension as com.android.build.gradle.BaseExtension
                if (android.namespace == null || android.namespace!!.isEmpty()) {
                    android.namespace = project.group.toString()
                }
            }
        }
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
