package com.muff.plugins

import com.muff.config.AppConfig
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.server.application.Application
import io.ktor.server.application.install
import io.ktor.server.plugins.cors.routing.CORS

fun Application.configureCors(corsConfig: AppConfig.CorsConfig) {
    install(CORS) {
        corsConfig.allowedHosts.forEach { host ->
            when {
                host.startsWith("https://") ->
                    allowHost(host.removePrefix("https://"), schemes = listOf("https"))
                host.startsWith("http://") ->
                    allowHost(host.removePrefix("http://"), schemes = listOf("http"))
                else ->
                    allowHost(host, schemes = listOf("http", "https"))
            }
        }
        allowHeader(HttpHeaders.ContentType)
        allowMethod(HttpMethod.Get)
        allowMethod(HttpMethod.Post)
        allowMethod(HttpMethod.Put)
        allowMethod(HttpMethod.Delete)
    }
}
