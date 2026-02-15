package com.muff.db.tables

import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp

object PopularityBuckets : Table("popularity_buckets") {
    val id = long("id").autoIncrement()
    val bucketStartAt = timestamp("bucket_start_at")
    val articleId = uuid("article_id").references(Articles.articleId)
    val openCount = integer("open_count")

    override val primaryKey = PrimaryKey(id)

    init {
        uniqueIndex(bucketStartAt, articleId)
        index(isUnique = false, bucketStartAt, openCount) // popular feed query
    }
}
