package com.muff.routes

import com.muff.TestDatabaseFactory
import com.muff.db.tables.Sources
import com.muff.model.SourceResponse
import com.muff.plugins.configureRouting
import com.muff.plugins.configureSerialization
import com.muff.plugins.configureStatusPages
import com.muff.service.CategoryClassifier
import com.muff.service.FeedService
import com.muff.service.RssPollingService
import io.ktor.client.call.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.testing.*
import kotlinx.datetime.Clock
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.transactions.transaction
import java.util.*
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals

class CatalogRoutesTest {
    @BeforeTest
    fun setup() {
        TestDatabaseFactory.init()
        TestDatabaseFactory.cleanup()
    }

    @Test
    fun `GET catalog sources returns active sources`() =
        testApplication {
            application {
                configureSerialization()
                configureStatusPages()
                val classifier = CategoryClassifier()
                val feedService = FeedService(classifier)
                val rssPollingService = RssPollingService(classifier)
                configureRouting(feedService, classifier, rssPollingService)
            }

            // Insert test data
            transaction {
                Sources.insert {
                    it[sourceId] = UUID.randomUUID()
                    it[name] = "Test Source"
                    it[rssUrl] = "https://example.com/rss"
                    it[siteUrl] = "https://example.com"
                    it[defaultCategory] = ""
                    it[status] = "active"
                    it[createdAt] = Clock.System.now()
                }
                Sources.insert {
                    it[sourceId] = UUID.randomUUID()
                    it[name] = "Inactive Source"
                    it[rssUrl] = "https://example.com/rss2"
                    it[siteUrl] = "https://example.com"
                    it[defaultCategory] = ""
                    it[status] = "inactive"
                    it[createdAt] = Clock.System.now()
                }
            }

            val client =
                createClient {
                    install(ContentNegotiation) { json() }
                }

            val response = client.get("/v1/catalog/sources")
            assertEquals(HttpStatusCode.OK, response.status)

            val sources = response.body<List<SourceResponse>>()
            assertEquals(1, sources.size)
            assertEquals("Test Source", sources[0].name)
        }

    @Test
    fun `GET catalog sources returns empty list when no sources`() =
        testApplication {
            application {
                configureSerialization()
                configureStatusPages()
                val classifier = CategoryClassifier()
                val feedService = FeedService(classifier)
                val rssPollingService = RssPollingService(classifier)
                configureRouting(feedService, classifier, rssPollingService)
            }

            val client =
                createClient {
                    install(ContentNegotiation) { json() }
                }

            val response = client.get("/v1/catalog/sources")
            assertEquals(HttpStatusCode.OK, response.status)

            val sources = response.body<List<SourceResponse>>()
            assertEquals(0, sources.size)
        }
}
