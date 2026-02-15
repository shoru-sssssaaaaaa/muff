package com.muff.db.tables

import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp

object Articles : Table("articles") {
    val articleId = uuid("article_id")
    val sourceId = uuid("source_id").references(Sources.sourceId)
    val title = text("title")
    val url = varchar("url", 2048).uniqueIndex()
    val publishedAt = timestamp("published_at")
    val thumbnailUrl = varchar("thumbnail_url", 2048).nullable()
    val category = varchar("category", 100)
    val ingestedAt = timestamp("ingested_at")

    override val primaryKey = PrimaryKey(articleId)

    init {
        index(isUnique = false, publishedAt, articleId) // cursor pagination
        index(isUnique = false, category, publishedAt, articleId) // category feed
    }
}
