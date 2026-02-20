package com.muff.routes

import com.muff.model.CreateCategoryRuleRequest
import com.muff.model.CreateSourceRequest
import com.muff.model.ErrorResponse
import com.muff.model.FeedCursor
import com.muff.model.UpdateCategoryRuleRequest
import com.muff.model.UpdateSourceRequest
import com.muff.service.CategoryClassifier
import com.muff.service.FeedService
import com.muff.service.RssPollingService
import io.ktor.http.HttpStatusCode
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.delete
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.put
import io.ktor.server.routing.route

fun Route.adminRoutes(
    feedService: FeedService,
    categoryClassifier: CategoryClassifier,
    rssPollingService: RssPollingService,
) {
    route("/admin") {
        get("/articles") {
            val limit = (call.queryParameters["limit"]?.toIntOrNull() ?: 20).coerceIn(1, 50)
            val cursorParam = call.queryParameters["cursor"]
            val cursor = cursorParam?.let { FeedCursor.decode(it) }

            if (cursorParam != null && cursor == null) {
                call.respond(HttpStatusCode.BadRequest, ErrorResponse("bad_request", "Invalid cursor"))
                return@get
            }

            val sourceId = call.queryParameters["source_id"]
            val category = call.queryParameters["category"]

            val feed = feedService.getAdminArticles(sourceId, category, cursor, limit)
            call.respond(feed)
        }

        get("/popular") {
            val limit = (call.queryParameters["limit"]?.toIntOrNull() ?: 20).coerceIn(1, 50)
            val feed = feedService.getPopularFeed(limit)
            call.respond(feed)
        }

        get("/sources") {
            val sources = feedService.getAllSources()
            call.respond(sources)
        }

        post("/sources") {
            val req = call.receive<CreateSourceRequest>()
            if (req.name.isBlank() || req.rssUrl.isBlank() || req.siteUrl.isBlank()) {
                call.respond(HttpStatusCode.BadRequest, ErrorResponse("bad_request", "All fields are required"))
                return@post
            }
            val source = feedService.createSource(req)
            call.respond(HttpStatusCode.Created, source)
        }

        put("/sources/{id}") {
            val id =
                call.parameters["id"]
                    ?: return@put call.respond(
                        HttpStatusCode.BadRequest,
                        ErrorResponse("bad_request", "Missing source id"),
                    )
            val req = call.receive<UpdateSourceRequest>()
            if (req.status !in listOf("active", "inactive")) {
                call.respond(
                    HttpStatusCode.BadRequest,
                    ErrorResponse("bad_request", "Status must be 'active' or 'inactive'"),
                )
                return@put
            }
            val source = feedService.updateSource(id, req)
            if (source == null) {
                call.respond(HttpStatusCode.NotFound, ErrorResponse("not_found", "Source not found"))
            } else {
                call.respond(source)
            }
        }

        delete("/sources/{id}") {
            val id =
                call.parameters["id"]
                    ?: return@delete call.respond(
                        HttpStatusCode.BadRequest,
                        ErrorResponse("bad_request", "Missing source id"),
                    )
            val deleted = feedService.deleteSource(id)
            if (deleted) {
                call.respond(mapOf("status" to "ok"))
            } else {
                call.respond(HttpStatusCode.NotFound, ErrorResponse("not_found", "Source not found"))
            }
        }

        // Category Rules CRUD

        get("/category-rules") {
            val rules = feedService.getCategoryRules()
            call.respond(rules)
        }

        post("/category-rules") {
            val req = call.receive<CreateCategoryRuleRequest>()
            if (req.name.isBlank()) {
                call.respond(HttpStatusCode.BadRequest, ErrorResponse("bad_request", "Name is required"))
                return@post
            }
            val rule = feedService.createCategoryRule(req)
            call.respond(HttpStatusCode.Created, rule)
        }

        put("/category-rules/{id}") {
            val id =
                call.parameters["id"]
                    ?: return@put call.respond(
                        HttpStatusCode.BadRequest,
                        ErrorResponse("bad_request", "Missing category rule id"),
                    )
            val req = call.receive<UpdateCategoryRuleRequest>()
            if (req.name.isBlank()) {
                call.respond(HttpStatusCode.BadRequest, ErrorResponse("bad_request", "Name is required"))
                return@put
            }
            val rule = feedService.updateCategoryRule(id, req)
            if (rule == null) {
                call.respond(HttpStatusCode.NotFound, ErrorResponse("not_found", "Category rule not found"))
            } else {
                call.respond(rule)
            }
        }

        delete("/category-rules/{id}") {
            val id =
                call.parameters["id"]
                    ?: return@delete call.respond(
                        HttpStatusCode.BadRequest,
                        ErrorResponse("bad_request", "Missing category rule id"),
                    )
            val deleted = feedService.deleteCategoryRule(id)
            if (deleted) {
                call.respond(mapOf("status" to "ok"))
            } else {
                call.respond(HttpStatusCode.NotFound, ErrorResponse("not_found", "Category rule not found"))
            }
        }

        post("/category-rules/reclassify") {
            rssPollingService.reclassifyAll()
            call.respond(mapOf("status" to "ok"))
        }
    }
}
