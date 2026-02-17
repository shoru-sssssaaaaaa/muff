package com.muff.plugins

import com.muff.config.AppConfig
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.plugins.cors.routing.*

fun Application.configureCors(corsConfig: AppConfig.CorsConfig) {
    install(CORS) {
        corsConfig.allowedHosts.forEach { host ->
            allowHost(host)
        }
        allowHeader(HttpHeaders.ContentType)
        allowMethod(HttpMethod.Get)
        allowMethod(HttpMethod.Post)
        allowMethod(HttpMethod.Put)
        allowMethod(HttpMethod.Delete)
    }
}
