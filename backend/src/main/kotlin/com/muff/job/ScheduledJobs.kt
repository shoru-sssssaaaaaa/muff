package com.muff.job

import com.muff.service.AppAttestService
import com.muff.service.FeedService
import com.muff.service.PopularityService
import com.muff.service.RssPollingService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory
import kotlin.time.Duration.Companion.hours
import kotlin.time.Duration.Companion.minutes

class ScheduledJobs(
    private val rssPollingService: RssPollingService,
    private val popularityService: PopularityService,
    private val attestService: AppAttestService,
    private val feedService: FeedService,
    private val rssIntervalMinutes: Long,
    private val popularityIntervalMinutes: Long,
) {
    private val logger = LoggerFactory.getLogger(ScheduledJobs::class.java)
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    fun start() {
        logger.info(
            "Starting scheduled jobs — RSS polling: {}min, Popularity: {}min",
            rssIntervalMinutes,
            popularityIntervalMinutes,
        )

        scope.launch {
            while (isActive) {
                try {
                    rssPollingService.pollAll()
                } catch (e: Exception) {
                    logger.error("RSS polling job failed", e)
                }
                delay(rssIntervalMinutes.minutes)
            }
        }

        scope.launch {
            while (isActive) {
                delay(popularityIntervalMinutes.minutes)
                try {
                    popularityService.aggregate()
                } catch (e: Exception) {
                    logger.error("Popularity aggregation job failed", e)
                }
            }
        }

        scope.launch {
            while (isActive) {
                delay(1.hours)
                try {
                    val deleted = attestService.cleanupExpiredChallenges()
                    if (deleted > 0) {
                        logger.debug("Cleaned up {} expired attest challenges", deleted)
                    }
                } catch (e: Exception) {
                    logger.error("Attest challenge cleanup job failed", e)
                }
            }
        }

        scope.launch {
            while (isActive) {
                delay(24.hours)
                try {
                    feedService.cleanupOldArticles(48.hours)
                } catch (e: Exception) {
                    logger.error("Article cleanup job failed", e)
                }
            }
        }
    }

    fun stop() {
        logger.info("Stopping scheduled jobs")
        scope.cancel()
    }
}
