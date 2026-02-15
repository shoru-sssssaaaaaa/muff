package com.muff.db.tables

import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp

object Sources : Table("sources") {
    val sourceId = uuid("source_id")
    val name = varchar("name", 255)
    val rssUrl = varchar("rss_url", 2048).uniqueIndex()
    val siteUrl = varchar("site_url", 2048)
    val defaultCategory = varchar("default_category", 100)
    val status = varchar("status", 20).default("active") // "active" | "inactive"
    val lastFetchAt = timestamp("last_fetch_at").nullable()
    val lastSuccessAt = timestamp("last_success_at").nullable()
    val consecutiveFailures = integer("consecutive_failures").default(0)
    val createdAt = timestamp("created_at")

    override val primaryKey = PrimaryKey(sourceId)
}
