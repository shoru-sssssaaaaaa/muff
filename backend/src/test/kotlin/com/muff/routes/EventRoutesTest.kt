package com.muff.routes

import com.muff.TestDatabaseFactory
import com.muff.db.tables.OpenEvents
import com.muff.model.OpenEventRequest
import com.muff.plugins.configureRouting
import com.muff.plugins.configureSerialization
import com.muff.plugins.configureStatusPages
import com.muff.service.FeedService
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.testing.*
import kotlinx.datetime.Clock
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals

class EventRoutesTest {

    @BeforeTest
    fun setup() {
        TestDatabaseFactory.init()
        TestDatabaseFactory.cleanup()
    }

    @Test
    fun `POST events open creates event`() = testApplication {
        application {
            configureSerialization()
            configureStatusPages()
            configureRouting(FeedService())
        }

        val client = createClient {
            install(ContentNegotiation) { json() }
        }

        val request = OpenEventRequest(
            articleUrl = "https://example.com/article/1",
            occurredAt = Clock.System.now().toString(),
            anonDeviceIdHash = "abc123hash",
            appVersion = "1.0.0",
        )

        val response = client.post("/v1/events/open") {
            contentType(ContentType.Application.Json)
            setBody(request)
        }

        assertEquals(HttpStatusCode.Created, response.status)

        val count = transaction { OpenEvents.selectAll().count() }
        assertEquals(1, count)
    }

    @Test
    fun `POST events open rejects empty article_url`() = testApplication {
        application {
            configureSerialization()
            configureStatusPages()
            configureRouting(FeedService())
        }

        val client = createClient {
            install(ContentNegotiation) { json() }
        }

        val request = OpenEventRequest(
            articleUrl = "",
            occurredAt = Clock.System.now().toString(),
            anonDeviceIdHash = "abc123hash",
            appVersion = "1.0.0",
        )

        val response = client.post("/v1/events/open") {
            contentType(ContentType.Application.Json)
            setBody(request)
        }

        assertEquals(HttpStatusCode.BadRequest, response.status)
    }

    @Test
    fun `POST events open rejects invalid occurred_at`() = testApplication {
        application {
            configureSerialization()
            configureStatusPages()
            configureRouting(FeedService())
        }

        val client = createClient {
            install(ContentNegotiation) { json() }
        }

        val request = OpenEventRequest(
            articleUrl = "https://example.com/article/1",
            occurredAt = "not-a-date",
            anonDeviceIdHash = "abc123hash",
            appVersion = "1.0.0",
        )

        val response = client.post("/v1/events/open") {
            contentType(ContentType.Application.Json)
            setBody(request)
        }

        assertEquals(HttpStatusCode.BadRequest, response.status)
    }
}
