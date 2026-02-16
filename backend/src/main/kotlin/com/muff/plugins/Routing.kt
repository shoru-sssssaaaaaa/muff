package com.muff.plugins

import com.muff.routes.adminRoutes
import com.muff.routes.catalogRoutes
import com.muff.routes.eventRoutes
import com.muff.routes.feedRoutes
import com.muff.service.FeedService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.http.content.*
import io.ktor.server.plugins.swagger.*
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun Application.configureRouting(feedService: FeedService) {
    routing {
        get("/health") {
            call.respondText("""{"status":"ok"}""", ContentType.Application.Json)
        }

        swaggerUI(path = "swagger", swaggerFile = "openapi/documentation.yaml")
        catalogRoutes(feedService)
        feedRoutes(feedService)
        eventRoutes()
        adminRoutes(feedService)

        // Serve admin UI static files
        staticResources("/admin-ui", "admin")
    }
}
