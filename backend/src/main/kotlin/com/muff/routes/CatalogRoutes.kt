package com.muff.routes

import com.muff.service.FeedService
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun Route.catalogRoutes(feedService: FeedService) {
    route("/v1/catalog") {
        get("/sources") {
            val sources = feedService.getSources()
            call.respond(sources)
        }
    }
}
