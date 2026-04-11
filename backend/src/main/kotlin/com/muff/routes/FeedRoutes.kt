package com.muff.routes

import com.muff.model.ErrorResponse
import com.muff.model.FeedCursor
import com.muff.service.FeedService
import com.muff.service.RssPollingService
import io.ktor.http.HttpStatusCode
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.route
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import java.util.concurrent.atomic.AtomicReference
import kotlin.time.Duration.Companion.minutes

private val lastPollAt = AtomicReference(Instant.DISTANT_PAST)

fun Route.feedRoutes(feedService: FeedService, rssPollingService: RssPollingService? = null) {
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
            val category =
                call.pathParameters["category"]
                    ?: return@get call.respond(
                        HttpStatusCode.BadRequest,
                        ErrorResponse("bad_request", "Missing category"),
                    )

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

        if (rssPollingService != null) {
            post("/refresh") {
                val now = Clock.System.now()
                val last = lastPollAt.get()
                if (now - last < 1.minutes) {
                    call.respond(mapOf("status" to "skipped"))
                    return@post
                }
                lastPollAt.set(now)
                rssPollingService.pollAll()
                call.respond(mapOf("status" to "ok"))
            }
        }
    }
}
