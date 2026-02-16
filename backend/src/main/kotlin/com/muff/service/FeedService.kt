package com.muff.service

import com.muff.db.tables.Articles
import com.muff.db.tables.PopularityBuckets
import com.muff.db.tables.Sources
import com.muff.model.*
import kotlinx.datetime.Clock
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.SqlExpressionBuilder.less
import org.jetbrains.exposed.sql.transactions.transaction
import java.util.UUID

class FeedService {
    fun getSources(): List<SourceResponse> =
        transaction {
            Sources.selectAll()
                .where { Sources.status eq "active" }
                .orderBy(Sources.name to SortOrder.ASC)
                .map { row ->
                    SourceResponse(
                        sourceId = row[Sources.sourceId].toString(),
                        name = row[Sources.name],
                        rssUrl = row[Sources.rssUrl],
                        siteUrl = row[Sources.siteUrl],
                        defaultCategory = row[Sources.defaultCategory],
                        status = row[Sources.status],
                    )
                }
        }

    fun getNewFeed(
        cursor: FeedCursor?,
        limit: Int,
    ): FeedResponse =
        transaction {
            val query =
                Articles.innerJoin(Sources, { Articles.sourceId }, { Sources.sourceId })
                    .selectAll()

            if (cursor != null) {
                query.andWhere {
                    (Articles.publishedAt less cursor.publishedAt) or
                        ((Articles.publishedAt eq cursor.publishedAt) and (Articles.articleId less cursor.articleId))
                }
            }

            val rows =
                query
                    .orderBy(Articles.publishedAt to SortOrder.DESC, Articles.articleId to SortOrder.DESC)
                    .limit(limit + 1)
                    .toList()

            buildFeedResponse(rows, limit)
        }

    fun getCategoryFeed(
        category: String,
        cursor: FeedCursor?,
        limit: Int,
    ): FeedResponse =
        transaction {
            val query =
                Articles.innerJoin(Sources, { Articles.sourceId }, { Sources.sourceId })
                    .selectAll()
                    .andWhere { Articles.category eq category }

            if (cursor != null) {
                query.andWhere {
                    (Articles.publishedAt less cursor.publishedAt) or
                        ((Articles.publishedAt eq cursor.publishedAt) and (Articles.articleId less cursor.articleId))
                }
            }

            val rows =
                query
                    .orderBy(Articles.publishedAt to SortOrder.DESC, Articles.articleId to SortOrder.DESC)
                    .limit(limit + 1)
                    .toList()

            buildFeedResponse(rows, limit)
        }

    fun getPopularFeed(limit: Int): FeedResponse =
        transaction {
            val latestBucket =
                PopularityBuckets
                    .select(PopularityBuckets.bucketStartAt)
                    .orderBy(PopularityBuckets.bucketStartAt to SortOrder.DESC)
                    .limit(1)
                    .firstOrNull()
                    ?.get(PopularityBuckets.bucketStartAt)
                    ?: return@transaction FeedResponse(items = emptyList())

            val rows =
                PopularityBuckets
                    .innerJoin(Articles, { PopularityBuckets.articleId }, { Articles.articleId })
                    .innerJoin(Sources, { Articles.sourceId }, { Sources.sourceId })
                    .selectAll()
                    .andWhere { PopularityBuckets.bucketStartAt eq latestBucket }
                    .orderBy(PopularityBuckets.openCount to SortOrder.DESC)
                    .limit(limit)
                    .toList()

            val items =
                rows.map { row ->
                    ArticleResponse(
                        articleId = row[Articles.articleId].toString(),
                        sourceId = row[Articles.sourceId].toString(),
                        sourceName = row[Sources.name],
                        title = row[Articles.title],
                        url = row[Articles.url],
                        publishedAt = row[Articles.publishedAt].toString(),
                        thumbnailUrl = row[Articles.thumbnailUrl],
                        category = row[Articles.category],
                        viewCount = row[PopularityBuckets.openCount],
                    )
                }.distinctBy { it.title }

            FeedResponse(items = items)
        }

    // Admin CRUD

    fun getAllSources(): List<SourceResponse> =
        transaction {
            Sources.selectAll()
                .orderBy(Sources.name to SortOrder.ASC)
                .map { it.toSourceResponse() }
        }

    fun createSource(req: CreateSourceRequest): SourceResponse =
        transaction {
            val id = UUID.randomUUID()
            val now = Clock.System.now()
            Sources.insert {
                it[sourceId] = id
                it[name] = req.name
                it[rssUrl] = req.rssUrl
                it[siteUrl] = req.siteUrl
                it[defaultCategory] = req.defaultCategory
                it[status] = "active"
                it[createdAt] = now
            }
            SourceResponse(
                sourceId = id.toString(),
                name = req.name,
                rssUrl = req.rssUrl,
                siteUrl = req.siteUrl,
                defaultCategory = req.defaultCategory,
                status = "active",
            )
        }

    fun updateSource(
        id: String,
        req: UpdateSourceRequest,
    ): SourceResponse? =
        transaction {
            val uuid = UUID.fromString(id)
            val updated =
                Sources.update({ Sources.sourceId eq uuid }) {
                    it[name] = req.name
                    it[rssUrl] = req.rssUrl
                    it[siteUrl] = req.siteUrl
                    it[defaultCategory] = req.defaultCategory
                    it[status] = req.status
                }
            if (updated == 0) return@transaction null
            Sources.selectAll().where { Sources.sourceId eq uuid }.firstOrNull()?.toSourceResponse()
        }

    fun getAdminArticles(
        sourceId: String?,
        category: String?,
        cursor: FeedCursor?,
        limit: Int,
    ): FeedResponse =
        transaction {
            val query =
                Articles.innerJoin(Sources, { Articles.sourceId }, { Sources.sourceId })
                    .selectAll()

            if (sourceId != null) {
                val uuid = UUID.fromString(sourceId)
                query.andWhere { Articles.sourceId eq uuid }
            }
            if (category != null) {
                query.andWhere { Articles.category eq category }
            }
            if (cursor != null) {
                query.andWhere {
                    (Articles.publishedAt less cursor.publishedAt) or
                        ((Articles.publishedAt eq cursor.publishedAt) and (Articles.articleId less cursor.articleId))
                }
            }

            val rows =
                query
                    .orderBy(Articles.publishedAt to SortOrder.DESC, Articles.articleId to SortOrder.DESC)
                    .limit(limit + 1)
                    .toList()

            buildFeedResponse(rows, limit)
        }

    fun deleteSource(id: String): Boolean =
        transaction {
            val uuid = UUID.fromString(id)
            Articles.deleteWhere { Articles.sourceId eq uuid }
            Sources.deleteWhere { sourceId eq uuid } > 0
        }

    private fun ResultRow.toSourceResponse() =
        SourceResponse(
            sourceId = this[Sources.sourceId].toString(),
            name = this[Sources.name],
            rssUrl = this[Sources.rssUrl],
            siteUrl = this[Sources.siteUrl],
            defaultCategory = this[Sources.defaultCategory],
            status = this[Sources.status],
            consecutiveFailures = this[Sources.consecutiveFailures],
            lastFetchAt = this[Sources.lastFetchAt]?.toString(),
            lastSuccessAt = this[Sources.lastSuccessAt]?.toString(),
        )

    private fun buildFeedResponse(
        rows: List<ResultRow>,
        limit: Int,
    ): FeedResponse {
        val hasMore = rows.size > limit
        val items =
            rows.take(limit).map { row ->
                ArticleResponse(
                    articleId = row[Articles.articleId].toString(),
                    sourceId = row[Articles.sourceId].toString(),
                    sourceName = row[Sources.name],
                    title = row[Articles.title],
                    url = row[Articles.url],
                    publishedAt = row[Articles.publishedAt].toString(),
                    thumbnailUrl = row[Articles.thumbnailUrl],
                    category = row[Articles.category],
                )
            }.distinctBy { it.title }

        val nextCursor =
            if (hasMore && items.isNotEmpty()) {
                val last = rows[limit - 1]
                FeedCursor(
                    publishedAt = last[Articles.publishedAt],
                    articleId = last[Articles.articleId],
                ).encode()
            } else {
                null
            }

        return FeedResponse(items = items, nextCursor = nextCursor)
    }
}
