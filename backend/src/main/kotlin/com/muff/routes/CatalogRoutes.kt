package com.muff.routes

import com.muff.db.tables.CategoryRules
import com.muff.service.FeedService
import io.ktor.server.response.respond
import io.ktor.server.routing.Route
import io.ktor.server.routing.get
import io.ktor.server.routing.route
import org.jetbrains.exposed.sql.SortOrder
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction

fun Route.catalogRoutes(feedService: FeedService) {
    route("/v1/catalog") {
        get("/sources") {
            val sources = feedService.getSources()
            call.respond(sources)
        }

        get("/categories") {
            val categories =
                transaction {
                    CategoryRules.selectAll()
                        .orderBy(CategoryRules.sortOrder to SortOrder.ASC)
                        .map { it[CategoryRules.name] }
                }
            call.respond(categories)
        }
    }
}
