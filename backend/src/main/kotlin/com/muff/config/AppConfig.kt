package com.muff.config

import io.ktor.server.application.*

data class AppConfig(
    val database: DatabaseConfig,
    val cors: CorsConfig,
    val jobs: JobsConfig,
) {
    data class DatabaseConfig(
        val url: String,
        val user: String,
        val password: String,
        val maxPoolSize: Int,
    )

    data class CorsConfig(
        val allowedHosts: List<String>,
    )

    data class JobsConfig(
        val rssPollingIntervalMinutes: Long,
        val popularityAggregationIntervalMinutes: Long,
    )

    companion object {
        fun load(environment: ApplicationEnvironment): AppConfig {
            val config = environment.config
            return AppConfig(
                database =
                    DatabaseConfig(
                        url = config.property("database.url").getString(),
                        user = config.property("database.user").getString(),
                        password = config.property("database.password").getString(),
                        maxPoolSize = config.property("database.maxPoolSize").getString().toInt(),
                    ),
                cors =
                    CorsConfig(
                        allowedHosts =
                            config.property("cors.allowedHosts").getString()
                                .split(",")
                                .map { it.trim() }
                                .filter { it.isNotEmpty() },
                    ),
                jobs =
                    JobsConfig(
                        rssPollingIntervalMinutes = config.property("jobs.rssPollingIntervalMinutes").getString().toLong(),
                        popularityAggregationIntervalMinutes =
                            config.property(
                                "jobs.popularityAggregationIntervalMinutes",
                            ).getString().toLong(),
                    ),
            )
        }
    }
}
