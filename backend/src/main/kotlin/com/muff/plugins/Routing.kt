package com.muff.plugins

import com.muff.routes.adminRoutes
import com.muff.routes.attestRoutes
import com.muff.routes.catalogRoutes
import com.muff.routes.eventRoutes
import com.muff.routes.feedRoutes
import com.muff.service.AppAttestService
import com.muff.service.CategoryClassifier
import com.muff.service.FeedService
import com.muff.service.RssPollingService
import io.ktor.http.ContentType
import io.ktor.server.application.Application
import io.ktor.server.http.content.staticResources
import io.ktor.server.plugins.swagger.swaggerUI
import io.ktor.server.response.respondText
import io.ktor.server.routing.get
import io.ktor.server.routing.routing

fun Application.configureRouting(
    feedService: FeedService,
    categoryClassifier: CategoryClassifier? = null,
    rssPollingService: RssPollingService? = null,
    attestService: AppAttestService? = null,
) {
    routing {
        get("/health") {
            call.respondText("""{"status":"ok"}""", ContentType.Application.Json)
        }

        swaggerUI(path = "swagger", swaggerFile = "openapi/documentation.yaml")
        if (attestService != null) {
            attestRoutes(attestService)
        }
        catalogRoutes(feedService)
        feedRoutes(feedService)
        eventRoutes()
        if (categoryClassifier != null && rssPollingService != null) {
            adminRoutes(feedService, categoryClassifier, rssPollingService)
        }

        // Serve admin UI static files
        staticResources("/admin-ui", "admin")
    }
}
