val kotlinVersion = "2.1.0"
val ktorVersion = "3.0.3"
val exposedVersion = "0.57.0"
val hikariVersion = "6.2.1"
val postgresVersion = "42.7.4"
val flywayVersion = "9.22.3"
val logbackVersion = "1.5.12"
val kotlinxDatetimeVersion = "0.6.1"
val romeVersion = "2.1.0"
val swaggerVersion = "2.2.22"

plugins {
    kotlin("jvm") version "2.1.0"
    kotlin("plugin.serialization") version "2.1.0"
    id("io.ktor.plugin") version "3.0.3"
    id("org.jlleitschuh.gradle.ktlint") version "12.1.2"
}

group = "com.muff"
version = "0.1.0"

application {
    mainClass.set("com.muff.ApplicationKt")
}

repositories {
    mavenCentral()
}

dependencies {
    // Ktor Server
    implementation("io.ktor:ktor-server-core:$ktorVersion")
    implementation("io.ktor:ktor-server-netty:$ktorVersion")
    implementation("io.ktor:ktor-server-content-negotiation:$ktorVersion")
    implementation("io.ktor:ktor-serialization-kotlinx-json:$ktorVersion")
    implementation("io.ktor:ktor-server-status-pages:$ktorVersion")
    implementation("io.ktor:ktor-server-cors:$ktorVersion")
    implementation("io.ktor:ktor-server-openapi:$ktorVersion")
    implementation("io.ktor:ktor-server-swagger:$ktorVersion")

    // Exposed ORM
    implementation("org.jetbrains.exposed:exposed-core:$exposedVersion")
    implementation("org.jetbrains.exposed:exposed-dao:$exposedVersion")
    implementation("org.jetbrains.exposed:exposed-jdbc:$exposedVersion")
    implementation("org.jetbrains.exposed:exposed-kotlin-datetime:$exposedVersion")

    // Database
    implementation("org.postgresql:postgresql:$postgresVersion")
    implementation("com.zaxxer:HikariCP:$hikariVersion")
    implementation("com.google.cloud.sql:postgres-socket-factory:1.21.0")

    // Flyway
    implementation("org.flywaydb:flyway-core:$flywayVersion")

    // Serialization
    implementation("org.jetbrains.kotlinx:kotlinx-datetime:$kotlinxDatetimeVersion")

    // OpenAPI / Swagger
    implementation("io.swagger.core.v3:swagger-core-jakarta:$swaggerVersion")

    // CBOR parsing for App Attest objects
    implementation("com.upokecenter:cbor:5.0.0-alpha2")

    // RSS Parser
    implementation("com.rometools:rome:$romeVersion")

    // Logging
    implementation("ch.qos.logback:logback-classic:$logbackVersion")
    implementation("net.logstash.logback:logstash-logback-encoder:8.0")

    // Test
    testImplementation("io.ktor:ktor-server-test-host:$ktorVersion")
    testImplementation("org.jetbrains.kotlin:kotlin-test:$kotlinVersion")
    testImplementation("io.ktor:ktor-client-content-negotiation:$ktorVersion")
    testImplementation("com.h2database:h2:2.3.232")
}

kotlin {
    jvmToolchain(21)
}

ktlint {
    android.set(false)
    version.set("0.50.0")
    verbose.set(true)
    outputToConsole.set(true)
    reporters {
        reporter(org.jlleitschuh.gradle.ktlint.reporter.ReporterType.PLAIN)
        reporter(org.jlleitschuh.gradle.ktlint.reporter.ReporterType.CHECKSTYLE)
    }
    filter {
        exclude("**/generated/**", "**/build/**")
        include("**/kotlin/**")
    }
}

// --- OpenAPI spec generation ---
val generateOpenApi by tasks.registering(JavaExec::class) {
    description = "Generate OpenAPI specification YAML from Kotlin code"
    group = "documentation"
    dependsOn("classes")
    mainClass.set("com.muff.openapi.OpenApiGeneratorKt")
    classpath =
        files(
            sourceSets["main"].output.classesDirs,
            configurations["runtimeClasspath"],
        )
    val outputFile = layout.buildDirectory.file("resources/main/openapi/documentation.yaml")
    args(outputFile.get().asFile.absolutePath)
    outputs.file(outputFile)
    doFirst {
        outputFile.get().asFile.parentFile.mkdirs()
    }
}

tasks.named("jar") { dependsOn(generateOpenApi) }
tasks.named("shadowJar") { dependsOn(generateOpenApi) }
tasks.named<JavaExec>("run") { dependsOn(generateOpenApi) }
