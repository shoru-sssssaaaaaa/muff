package com.muff.service

import com.muff.db.tables.Articles
import com.muff.db.tables.OpenEvents
import com.muff.db.tables.PopularityBuckets
import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import org.jetbrains.exposed.sql.and
import org.jetbrains.exposed.sql.count
import org.jetbrains.exposed.sql.innerJoin
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction
import org.jetbrains.exposed.sql.update
import org.slf4j.LoggerFactory
import kotlin.time.Duration.Companion.minutes

class PopularityService {
    private val logger = LoggerFactory.getLogger(PopularityService::class.java)

    fun aggregate() {
        val now = Clock.System.now()
        val bucketStart = alignToBucket(now)
        val windowStart = bucketStart - 30.minutes

        logger.info("Aggregating popularity for bucket: {} (window: {} to {})", bucketStart, windowStart, bucketStart)

        transaction {
            // Count open events per article_url in the 30-minute window
            val counts =
                OpenEvents
                    .innerJoin(Articles, { OpenEvents.articleUrl }, { Articles.url })
                    .select(Articles.articleId, OpenEvents.articleUrl.count())
                    .where {
                        (OpenEvents.occurredAt greaterEq windowStart) and
                            (OpenEvents.occurredAt less bucketStart)
                    }
                    .groupBy(Articles.articleId)
                    .toList()

            logger.info("Found {} articles with opens in window", counts.size)

            for (row in counts) {
                val articleId = row[Articles.articleId]
                val count = row[OpenEvents.articleUrl.count()].toInt()

                // Upsert: insert or update open_count
                val existing =
                    PopularityBuckets
                        .selectAll()
                        .where {
                            (PopularityBuckets.bucketStartAt eq bucketStart) and
                                (PopularityBuckets.articleId eq articleId)
                        }
                        .firstOrNull()

                if (existing != null) {
                    PopularityBuckets.update({
                        (PopularityBuckets.bucketStartAt eq bucketStart) and
                            (PopularityBuckets.articleId eq articleId)
                    }) {
                        it[openCount] = count
                    }
                } else {
                    PopularityBuckets.insert {
                        it[PopularityBuckets.bucketStartAt] = bucketStart
                        it[PopularityBuckets.articleId] = articleId
                        it[openCount] = count
                    }
                }
            }
        }

        logger.info("Popularity aggregation complete for bucket: {}", bucketStart)
    }

    /** Align to the nearest 30-minute boundary (floor) */
    private fun alignToBucket(instant: Instant): Instant {
        val epochSeconds = instant.epochSeconds
        val bucketSeconds = 30L * 60
        val aligned = (epochSeconds / bucketSeconds) * bucketSeconds
        return Instant.fromEpochSeconds(aligned)
    }
}
