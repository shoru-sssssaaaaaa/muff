package com.muff.routes

import com.muff.db.tables.OpenEvents
import com.muff.model.ErrorResponse
import com.muff.model.OpenEventRequest
import io.ktor.http.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.transactions.transaction
import java.util.*

fun Route.eventRoutes() {
    route("/v1/events") {
        post("/open") {
            val request = call.receive<OpenEventRequest>()

            if (request.articleUrl.isBlank() || request.anonDeviceIdHash.isBlank() || request.appVersion.isBlank()) {
                call.respond(HttpStatusCode.BadRequest, ErrorResponse("bad_request", "Missing required fields"))
                return@post
            }

            val occurredAt = try {
                Instant.parse(request.occurredAt)
            } catch (_: Exception) {
                call.respond(HttpStatusCode.BadRequest, ErrorResponse("bad_request", "Invalid occurred_at format"))
                return@post
            }

            val articleUuid = request.articleId?.let {
                try {
                    UUID.fromString(it)
                } catch (_: Exception) {
                    null
                }
            }

            transaction {
                OpenEvents.insert {
                    it[eventId] = UUID.randomUUID()
                    it[articleUrl] = request.articleUrl
                    it[articleId] = articleUuid
                    it[OpenEvents.occurredAt] = occurredAt
                    it[anonDeviceIdHash] = request.anonDeviceIdHash
                    it[appVersion] = request.appVersion
                    it[createdAt] = Clock.System.now()
                }
            }

            call.respond(HttpStatusCode.Created, mapOf("status" to "ok"))
        }
    }
}
