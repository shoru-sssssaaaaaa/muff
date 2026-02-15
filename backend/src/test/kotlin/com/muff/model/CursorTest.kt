package com.muff.model

import kotlinx.datetime.Instant
import java.util.*
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class CursorTest {

    @Test
    fun `encode and decode round-trip`() {
        val original = FeedCursor(
            publishedAt = Instant.parse("2026-01-15T10:30:00Z"),
            articleId = UUID.fromString("550e8400-e29b-41d4-a716-446655440000"),
        )

        val encoded = original.encode()
        val decoded = FeedCursor.decode(encoded)

        assertNotNull(decoded)
        assertEquals(original.publishedAt, decoded.publishedAt)
        assertEquals(original.articleId, decoded.articleId)
    }

    @Test
    fun `decode invalid string returns null`() {
        assertNull(FeedCursor.decode("not-valid-base64!!!"))
    }

    @Test
    fun `decode empty string returns null`() {
        assertNull(FeedCursor.decode(""))
    }

    @Test
    fun `decode base64 with wrong format returns null`() {
        val bad = Base64.getUrlEncoder().withoutPadding().encodeToString("no-pipe-here".toByteArray())
        assertNull(FeedCursor.decode(bad))
    }
}
