package com.muff.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SourceResponse(
    @SerialName("source_id") val sourceId: String,
    val name: String,
    @SerialName("rss_url") val rssUrl: String,
    @SerialName("site_url") val siteUrl: String,
    @SerialName("default_category") val defaultCategory: String,
    val status: String,
    @SerialName("consecutive_failures") val consecutiveFailures: Int = 0,
    @SerialName("last_fetch_at") val lastFetchAt: String? = null,
    @SerialName("last_success_at") val lastSuccessAt: String? = null,
)

@Serializable
data class ArticleResponse(
    @SerialName("article_id") val articleId: String,
    @SerialName("source_id") val sourceId: String,
    @SerialName("source_name") val sourceName: String,
    val title: String,
    val url: String,
    @SerialName("published_at") val publishedAt: String,
    @SerialName("thumbnail_url") val thumbnailUrl: String? = null,
    val category: String,
    @SerialName("view_count") val viewCount: Int? = null,
)

@Serializable
data class FeedResponse(
    val items: List<ArticleResponse>,
    @SerialName("next_cursor") val nextCursor: String? = null,
)

@Serializable
data class OpenEventRequest(
    @SerialName("article_url") val articleUrl: String,
    @SerialName("article_id") val articleId: String? = null,
    @SerialName("occurred_at") val occurredAt: String,
    @SerialName("anon_device_id_hash") val anonDeviceIdHash: String,
    @SerialName("app_version") val appVersion: String,
)

@Serializable
data class ErrorResponse(
    val error: String,
    val message: String,
)

// Admin DTOs

@Serializable
data class CreateSourceRequest(
    val name: String,
    @SerialName("rss_url") val rssUrl: String,
    @SerialName("site_url") val siteUrl: String,
    @SerialName("default_category") val defaultCategory: String,
)

@Serializable
data class UpdateSourceRequest(
    val name: String,
    @SerialName("rss_url") val rssUrl: String,
    @SerialName("site_url") val siteUrl: String,
    @SerialName("default_category") val defaultCategory: String,
    val status: String,
)
