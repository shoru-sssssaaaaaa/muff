package com.muff.db.tables

import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp

object OpenEvents : Table("open_events") {
    val eventId = uuid("event_id")
    val articleUrl = varchar("article_url", 2048)
    val articleId = uuid("article_id").nullable()
    val occurredAt = timestamp("occurred_at")
    val anonDeviceIdHash = varchar("anon_device_id_hash", 128)
    val appVersion = varchar("app_version", 50)
    val createdAt = timestamp("created_at")

    override val primaryKey = PrimaryKey(eventId)

    init {
        index(isUnique = false, occurredAt) // aggregation query
    }
}
