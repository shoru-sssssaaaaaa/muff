package com.muff.service

import com.muff.db.tables.Articles
import com.muff.db.tables.Sources
import com.rometools.rome.io.SyndFeedInput
import com.rometools.rome.io.XmlReader
import kotlinx.datetime.Clock
import kotlinx.datetime.toKotlinInstant
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction
import org.jetbrains.exposed.sql.update
import org.slf4j.LoggerFactory
import java.net.URI
import java.util.UUID

class RssPollingService(
    private val categoryClassifier: CategoryClassifier = CategoryClassifier(),
) {
    private val logger = LoggerFactory.getLogger(RssPollingService::class.java)

    fun reclassifyAll() {
        transaction {
            val rows = Articles.selectAll().toList()
            var updated = 0
            for (row in rows) {
                val title = row[Articles.title]
                val newCategory = categoryClassifier.classify(title)
                if (row[Articles.ruleCategory] != newCategory) {
                    Articles.update({ Articles.articleId eq row[Articles.articleId] }) {
                        it[ruleCategory] = newCategory
                    }
                    updated++
                }
            }
            logger.debug("Reclassified {} articles", updated)
        }
    }

    fun pollAll() {
        val sources =
            transaction {
                Sources.selectAll()
                    .where { Sources.status eq "active" }
                    .toList()
                    .map { row ->
                        SourceRecord(
                            sourceId = row[Sources.sourceId],
                            name = row[Sources.name],
                            rssUrl = row[Sources.rssUrl],
                        )
                    }
            }

        logger.debug("Polling {} active sources", sources.size)

        for (source in sources) {
            try {
                pollSource(source)
                markSuccess(source.sourceId)
            } catch (e: Exception) {
                logger.error("Failed to poll source: {} ({})", source.name, source.rssUrl, e)
                markFailure(source.sourceId)
            }
        }
    }

    private fun pollSource(source: SourceRecord) {
        val input = SyndFeedInput()
        val feed =
            URI(source.rssUrl).toURL().openStream().use { stream ->
                XmlReader(stream).use { reader ->
                    input.build(reader)
                }
            }

        val now = Clock.System.now()

        transaction {
            for (entry in feed.entries) {
                val articleUrl = normalizeUrl(entry.link ?: continue)
                val title = normalizeTitle(entry.title ?: continue)
                val publishedAt =
                    entry.publishedDate?.toInstant()?.toKotlinInstant()
                        ?: entry.updatedDate?.toInstant()?.toKotlinInstant()
                        ?: now

                val thumbnail = extractThumbnail(entry)

                // Upsert by URL
                val existing =
                    Articles.selectAll()
                        .where { Articles.url eq articleUrl }
                        .firstOrNull()

                if (existing == null) {
                    val rssCategories =
                        entry.categories
                            ?.mapNotNull { it.name?.trim() }
                            ?.filter { it.isNotEmpty() }
                            ?.joinToString(", ")
                            ?.ifEmpty { null }

                    Articles.insert {
                        it[articleId] = UUID.randomUUID()
                        it[Articles.sourceId] = source.sourceId
                        it[Articles.title] = title
                        it[Articles.url] = articleUrl
                        it[Articles.publishedAt] = publishedAt
                        it[thumbnailUrl] = thumbnail
                        it[category] = ""
                        it[rssCategory] = rssCategories
                        it[ruleCategory] = categoryClassifier.classify(title)
                        it[ingestedAt] = now
                    }
                }
            }
        }

        logger.debug("Polled source: {} — {} entries", source.name, feed.entries.size)
    }

    private fun normalizeTitle(title: String): String {
        return title
            .replace(Regex("[\\p{Cc}&&[^\\n\\t]]"), "") // remove control chars except newline/tab
            .replace(Regex("\\s+"), " ")
            .trim()
    }

    private fun normalizeUrl(url: String): String {
        return try {
            val uri = URI(url)
            val query = uri.query
            if (query.isNullOrBlank()) return url

            val filtered =
                query.split("&")
                    .filter { param ->
                        val key = param.substringBefore("=").lowercase()
                        !key.startsWith("utm_") && key != "ref" && key != "source"
                    }
                    .joinToString("&")

            val newQuery = filtered.ifBlank { null }
            URI(uri.scheme, uri.authority, uri.path, newQuery, uri.fragment).toString()
        } catch (_: Exception) {
            url
        }
    }

    private fun extractThumbnail(entry: com.rometools.rome.feed.synd.SyndEntry): String? {
        // Try media:thumbnail via foreign markup (media:thumbnail element)
        for (element in entry.foreignMarkup) {
            if (element.name == "thumbnail" && element.namespaceURI.contains("media")) {
                val url = element.getAttributeValue("url")
                if (!url.isNullOrBlank()) return url
            }
        }

        // Try enclosure (image type)
        for (enclosure in entry.enclosures) {
            if (enclosure.type?.startsWith("image/") == true) {
                return enclosure.url
            }
        }

        return null
    }

    private fun markSuccess(sourceId: UUID) {
        val now = Clock.System.now()
        transaction {
            Sources.update({ Sources.sourceId eq sourceId }) {
                it[lastFetchAt] = now
                it[lastSuccessAt] = now
                it[consecutiveFailures] = 0
            }
        }
    }

    private fun markFailure(sourceId: UUID) {
        val now = Clock.System.now()
        transaction {
            val currentFailures =
                Sources.selectAll()
                    .where { Sources.sourceId eq sourceId }
                    .firstOrNull()
                    ?.get(Sources.consecutiveFailures) ?: 0

            Sources.update({ Sources.sourceId eq sourceId }) {
                it[lastFetchAt] = now
                it[consecutiveFailures] = currentFailures + 1
            }
        }
    }

    private data class SourceRecord(
        val sourceId: UUID,
        val name: String,
        val rssUrl: String,
    )
}
