package com.muff.routes

import com.muff.model.ErrorResponse
import com.muff.model.FeedCursor
import com.muff.service.FeedService
import io.ktor.http.*
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun Route.feedRoutes(feedService: FeedService) {
    route("/v1/feed") {
        get("/new") {
            val limit = (call.queryParameters["limit"]?.toIntOrNull() ?: 20).coerceIn(1, 50)
            val cursorParam = call.queryParameters["cursor"]
            val cursor = cursorParam?.let { FeedCursor.decode(it) }

            if (cursorParam != null && cursor == null) {
                call.respond(HttpStatusCode.BadRequest, ErrorResponse("bad_request", "Invalid cursor"))
                return@get
            }

            val feed = feedService.getNewFeed(cursor, limit)
            call.respond(feed)
        }

        get("/popular") {
            val limit = (call.queryParameters["limit"]?.toIntOrNull() ?: 20).coerceIn(1, 50)
            val feed = feedService.getPopularFeed(limit)
            call.respond(feed)
        }

        get("/category/{category}") {
            val category = call.pathParameters["category"]
                ?: return@get call.respond(HttpStatusCode.BadRequest, ErrorResponse("bad_request", "Missing category"))

            val limit = (call.queryParameters["limit"]?.toIntOrNull() ?: 20).coerceIn(1, 50)
            val cursorParam = call.queryParameters["cursor"]
            val cursor = cursorParam?.let { FeedCursor.decode(it) }

            if (cursorParam != null && cursor == null) {
                call.respond(HttpStatusCode.BadRequest, ErrorResponse("bad_request", "Invalid cursor"))
                return@get
            }

            val feed = feedService.getCategoryFeed(category, cursor, limit)
            call.respond(feed)
        }
    }
}
