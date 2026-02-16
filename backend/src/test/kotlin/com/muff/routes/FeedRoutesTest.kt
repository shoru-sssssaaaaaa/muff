package com.muff.routes

import com.muff.TestDatabaseFactory
import com.muff.db.tables.Articles
import com.muff.db.tables.Sources
import com.muff.model.FeedResponse
import com.muff.plugins.configureRouting
import com.muff.plugins.configureSerialization
import com.muff.plugins.configureStatusPages
import com.muff.service.FeedService
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
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.time.Duration.Companion.hours

class FeedRoutesTest {
    private val sourceId = UUID.randomUUID()

    @BeforeTest
    fun setup() {
        TestDatabaseFactory.init()
        TestDatabaseFactory.cleanup()

        transaction {
            Sources.insert {
                it[Sources.sourceId] = this@FeedRoutesTest.sourceId
                it[name] = "Test Source"
                it[rssUrl] = "https://example.com/rss"
                it[siteUrl] = "https://example.com"
                it[defaultCategory] = "news"
                it[status] = "active"
                it[createdAt] = Clock.System.now()
            }
        }
    }

    @Test
    fun `GET feed new returns articles in descending order`() =
        testApplication {
            application {
                configureSerialization()
                configureStatusPages()
                configureRouting(FeedService())
            }

            val now = Clock.System.now()
            transaction {
                for (i in 1..5) {
                    Articles.insert {
                        it[articleId] = UUID.randomUUID()
                        it[Articles.sourceId] = this@FeedRoutesTest.sourceId
                        it[title] = "Article $i"
                        it[url] = "https://example.com/article/$i"
                        it[publishedAt] = now - (i.hours)
                        it[category] = "news"
                        it[ingestedAt] = now
                    }
                }
            }

            val client =
                createClient {
                    install(ContentNegotiation) { json() }
                }

            val response = client.get("/v1/feed/new?limit=3")
            assertEquals(HttpStatusCode.OK, response.status)

            val feed = response.body<FeedResponse>()
            assertEquals(3, feed.items.size)
            assertNotNull(feed.nextCursor)
            assertEquals("Article 1", feed.items[0].title) // most recent first
        }

    @Test
    fun `GET feed new with cursor paginates correctly`() =
        testApplication {
            application {
                configureSerialization()
                configureStatusPages()
                configureRouting(FeedService())
            }

            val now = Clock.System.now()
            transaction {
                for (i in 1..5) {
                    Articles.insert {
                        it[articleId] = UUID.randomUUID()
                        it[Articles.sourceId] = this@FeedRoutesTest.sourceId
                        it[title] = "Article $i"
                        it[url] = "https://example.com/article-page/$i"
                        it[publishedAt] = now - (i.hours)
                        it[category] = "news"
                        it[ingestedAt] = now
                    }
                }
            }

            val client =
                createClient {
                    install(ContentNegotiation) { json() }
                }

            // Get first page
            val page1 = client.get("/v1/feed/new?limit=2").body<FeedResponse>()
            assertEquals(2, page1.items.size)
            assertNotNull(page1.nextCursor)

            // Get second page
            val page2 = client.get("/v1/feed/new?limit=2&cursor=${page1.nextCursor}").body<FeedResponse>()
            assertEquals(2, page2.items.size)
            assertNotNull(page2.nextCursor)

            // Get third page
            val page3 = client.get("/v1/feed/new?limit=2&cursor=${page2.nextCursor}").body<FeedResponse>()
            assertEquals(1, page3.items.size)
            assertNull(page3.nextCursor)
        }

    @Test
    fun `GET feed category filters by category`() =
        testApplication {
            application {
                configureSerialization()
                configureStatusPages()
                configureRouting(FeedService())
            }

            val now = Clock.System.now()
            transaction {
                Articles.insert {
                    it[articleId] = UUID.randomUUID()
                    it[Articles.sourceId] = this@FeedRoutesTest.sourceId
                    it[title] = "News Article"
                    it[url] = "https://example.com/news/1"
                    it[publishedAt] = now
                    it[category] = "news"
                    it[ingestedAt] = now
                }
                Articles.insert {
                    it[articleId] = UUID.randomUUID()
                    it[Articles.sourceId] = this@FeedRoutesTest.sourceId
                    it[title] = "Sports Article"
                    it[url] = "https://example.com/sports/1"
                    it[publishedAt] = now
                    it[category] = "sports"
                    it[ingestedAt] = now
                }
            }

            val client =
                createClient {
                    install(ContentNegotiation) { json() }
                }

            val response = client.get("/v1/feed/category/sports")
            val feed = response.body<FeedResponse>()
            assertEquals(1, feed.items.size)
            assertEquals("Sports Article", feed.items[0].title)
        }

    @Test
    fun `GET feed new with invalid cursor returns 400`() =
        testApplication {
            application {
                configureSerialization()
                configureStatusPages()
                configureRouting(FeedService())
            }

            val client =
                createClient {
                    install(ContentNegotiation) { json() }
                }

            val response = client.get("/v1/feed/new?cursor=invalid-cursor")
            assertEquals(HttpStatusCode.BadRequest, response.status)
        }

    @Test
    fun `GET feed popular returns empty when no buckets`() =
        testApplication {
            application {
                configureSerialization()
                configureStatusPages()
                configureRouting(FeedService())
            }

            val client =
                createClient {
                    install(ContentNegotiation) { json() }
                }

            val response = client.get("/v1/feed/popular")
            assertEquals(HttpStatusCode.OK, response.status)

            val feed = response.body<FeedResponse>()
            assertEquals(0, feed.items.size)
        }
}
