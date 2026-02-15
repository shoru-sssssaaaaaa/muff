package com.muff.model

import kotlinx.datetime.Instant
import java.util.*

data class FeedCursor(
    val publishedAt: Instant,
    val articleId: UUID,
) {
    fun encode(): String {
        val raw = "${publishedAt}|${articleId}"
        return Base64.getUrlEncoder().withoutPadding().encodeToString(raw.toByteArray())
    }

    companion object {
        fun decode(encoded: String): FeedCursor? {
            return try {
                val raw = String(Base64.getUrlDecoder().decode(encoded))
                val parts = raw.split("|", limit = 2)
                if (parts.size != 2) return null
                FeedCursor(
                    publishedAt = Instant.parse(parts[0]),
                    articleId = UUID.fromString(parts[1]),
                )
            } catch (_: Exception) {
                null
            }
        }
    }
}
