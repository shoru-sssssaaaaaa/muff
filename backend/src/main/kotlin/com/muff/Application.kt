package com.muff

import com.muff.config.AppConfig
import com.muff.db.DatabaseFactory
import com.muff.job.ScheduledJobs
import com.muff.plugins.configureCors
import com.muff.plugins.configureRouting
import com.muff.plugins.configureSerialization
import com.muff.plugins.configureStatusPages
import com.muff.service.FeedService
import com.muff.service.PopularityService
import com.muff.service.RssPollingService
import io.ktor.server.application.*
import io.ktor.server.plugins.calllogging.*
import org.slf4j.event.Level

fun main(args: Array<String>) {
    io.ktor.server.netty.EngineMain.main(args)
}

fun Application.module() {
    val appConfig = AppConfig.load(environment)

    // Database
    DatabaseFactory.init(appConfig.database)

    // Services
    val feedService = FeedService()
    val rssPollingService = RssPollingService()
    val popularityService = PopularityService()

    // Plugins
    install(CallLogging) {
        level = Level.INFO
    }
    configureCors(appConfig.cors)
    configureSerialization()
    configureStatusPages()
    configureRouting(feedService)

    // Scheduled Jobs
    val jobs =
        ScheduledJobs(
            rssPollingService = rssPollingService,
            popularityService = popularityService,
            rssIntervalMinutes = appConfig.jobs.rssPollingIntervalMinutes,
            popularityIntervalMinutes = appConfig.jobs.popularityAggregationIntervalMinutes,
        )
    jobs.start()

    monitor.subscribe(ApplicationStopped) {
        jobs.stop()
    }
}
