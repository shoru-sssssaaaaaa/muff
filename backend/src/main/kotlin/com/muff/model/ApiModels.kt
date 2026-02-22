package com.muff.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SourceResponse(
    @SerialName("source_id") val sourceId: String,
    val name: String,
    @SerialName("rss_url") val rssUrl: String,
    @SerialName("site_url") val siteUrl: String,
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

// Category Rules

@Serializable
data class CategoryRuleResponse(
    @SerialName("category_rule_id") val categoryRuleId: String,
    val name: String,
    val keywords: List<String>,
    @SerialName("is_default") val isDefault: Boolean,
    @SerialName("sort_order") val sortOrder: Int,
    @SerialName("article_count") val articleCount: Long = 0,
)

@Serializable
data class CreateCategoryRuleRequest(
    val name: String,
    val keywords: List<String>,
    @SerialName("is_default") val isDefault: Boolean = false,
    @SerialName("sort_order") val sortOrder: Int = 0,
)

@Serializable
data class UpdateCategoryRuleRequest(
    val name: String,
    val keywords: List<String>,
    @SerialName("is_default") val isDefault: Boolean = false,
    @SerialName("sort_order") val sortOrder: Int = 0,
)

// App Attest

@Serializable
data class AttestChallengeResponse(
    val challenge: String,
)

@Serializable
data class AttestVerifyRequest(
    @SerialName("key_id") val keyId: String,
    val attestation: String,
    val challenge: String,
)

@Serializable
data class AttestVerifyResponse(
    val verified: Boolean,
)

// Admin DTOs

@Serializable
data class CreateSourceRequest(
    val name: String,
    @SerialName("rss_url") val rssUrl: String,
    @SerialName("site_url") val siteUrl: String,
)

@Serializable
data class UpdateSourceRequest(
    val name: String,
    @SerialName("rss_url") val rssUrl: String,
    @SerialName("site_url") val siteUrl: String,
    val status: String,
)
