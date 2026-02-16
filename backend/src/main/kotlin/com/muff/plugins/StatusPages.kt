package com.muff.plugins

import com.muff.model.ErrorResponse
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.plugins.statuspages.*
import io.ktor.server.response.*
import org.slf4j.LoggerFactory

fun Application.configureStatusPages() {
    val logger = LoggerFactory.getLogger("StatusPages")

    install(StatusPages) {
        exception<IllegalArgumentException> { call, cause ->
            call.respond(
                HttpStatusCode.BadRequest,
                ErrorResponse("bad_request", cause.message ?: "Bad request"),
            )
        }

        exception<Throwable> { call, cause ->
            logger.error("Unhandled exception", cause)
            call.respond(
                HttpStatusCode.InternalServerError,
                ErrorResponse("internal_error", "Internal server error"),
            )
        }

        status(HttpStatusCode.NotFound) { call, _ ->
            call.respond(
                HttpStatusCode.NotFound,
                ErrorResponse("not_found", "Resource not found"),
            )
        }
    }
}
