package com.muff.service

import com.muff.db.tables.Articles
import com.muff.db.tables.CategoryRules
import com.muff.db.tables.PopularityBuckets
import com.muff.db.tables.Sources
import com.muff.model.ArticleResponse
import com.muff.model.CategoryRuleResponse
import com.muff.model.CreateCategoryRuleRequest
import com.muff.model.CreateSourceRequest
import com.muff.model.FeedCursor
import com.muff.model.FeedResponse
import com.muff.model.SourceResponse
import com.muff.model.UpdateCategoryRuleRequest
import com.muff.model.UpdateSourceRequest
import kotlinx.datetime.Clock
import org.jetbrains.exposed.sql.ResultRow
import org.jetbrains.exposed.sql.SortOrder
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.SqlExpressionBuilder.inSubQuery
import org.jetbrains.exposed.sql.SqlExpressionBuilder.less
import org.jetbrains.exposed.sql.and
import org.jetbrains.exposed.sql.andWhere
import org.jetbrains.exposed.sql.count
import org.jetbrains.exposed.sql.deleteWhere
import org.jetbrains.exposed.sql.innerJoin
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.or
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction
import org.jetbrains.exposed.sql.update
import org.slf4j.LoggerFactory
import java.util.UUID
import kotlin.time.Duration

class FeedService(
    private val categoryClassifier: CategoryClassifier,
) {
    private val logger = LoggerFactory.getLogger(FeedService::class.java)

    fun cleanupOldArticles(maxAge: Duration): Int =
        transaction {
            val cutoff = Clock.System.now().minus(maxAge)
            val oldArticleIds = Articles
                .select(Articles.articleId)
                .where { Articles.publishedAt less cutoff }

            val deletedBuckets = PopularityBuckets.deleteWhere {
                PopularityBuckets.articleId inSubQuery oldArticleIds
            }
            val deletedArticles = Articles.deleteWhere {
                Articles.publishedAt less cutoff
            }
            logger.debug(
                "Cleaned up {} old articles and {} popularity buckets (cutoff={})",
                deletedArticles,
                deletedBuckets,
                cutoff,
            )
            deletedArticles
        }

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
                    .andWhere { Articles.ruleCategory eq category }

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
                        category = row[Articles.ruleCategory] ?: "ネタ・その他",
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
                it[defaultCategory] = ""
                it[status] = "active"
                it[createdAt] = now
            }
            SourceResponse(
                sourceId = id.toString(),
                name = req.name,
                rssUrl = req.rssUrl,
                siteUrl = req.siteUrl,
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
                query.andWhere { Articles.ruleCategory eq category }
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

    // Category Rules CRUD

    fun getCategoryRules(): List<CategoryRuleResponse> =
        transaction {
            val counts =
                Articles
                    .select(Articles.ruleCategory, Articles.ruleCategory.count())
                    .groupBy(Articles.ruleCategory)
                    .associate { it[Articles.ruleCategory] to it[Articles.ruleCategory.count()] }

            CategoryRules.selectAll()
                .orderBy(CategoryRules.sortOrder to SortOrder.ASC)
                .map { it.toCategoryRuleResponse(counts[it[CategoryRules.name]] ?: 0L) }
        }

    fun createCategoryRule(req: CreateCategoryRuleRequest): CategoryRuleResponse =
        transaction {
            val id = UUID.randomUUID()
            val now = Clock.System.now()
            if (req.isDefault) {
                CategoryRules.update({ CategoryRules.isDefault eq true }) {
                    it[isDefault] = false
                }
            }
            CategoryRules.insert {
                it[categoryRuleId] = id
                it[name] = req.name
                it[keywords] = req.keywords.joinToString(",")
                it[isDefault] = req.isDefault
                it[sortOrder] = req.sortOrder
                it[createdAt] = now
            }
            categoryClassifier.reloadRules()
            CategoryRuleResponse(
                categoryRuleId = id.toString(),
                name = req.name,
                keywords = req.keywords,
                isDefault = req.isDefault,
                sortOrder = req.sortOrder,
            )
        }

    fun updateCategoryRule(
        id: String,
        req: UpdateCategoryRuleRequest,
    ): CategoryRuleResponse? =
        transaction {
            val uuid = UUID.fromString(id)
            if (req.isDefault) {
                CategoryRules.update({ CategoryRules.isDefault eq true }) {
                    it[isDefault] = false
                }
            }
            val updated =
                CategoryRules.update({ CategoryRules.categoryRuleId eq uuid }) {
                    it[name] = req.name
                    it[keywords] = req.keywords.joinToString(",")
                    it[isDefault] = req.isDefault
                    it[sortOrder] = req.sortOrder
                }
            if (updated == 0) return@transaction null
            categoryClassifier.reloadRules()
            CategoryRules.selectAll()
                .where { CategoryRules.categoryRuleId eq uuid }
                .firstOrNull()
                ?.toCategoryRuleResponse()
        }

    fun deleteCategoryRule(id: String): Boolean =
        transaction {
            val uuid = UUID.fromString(id)
            val deleted = CategoryRules.deleteWhere { categoryRuleId eq uuid } > 0
            if (deleted) categoryClassifier.reloadRules()
            deleted
        }

    private fun ResultRow.toCategoryRuleResponse(articleCount: Long = 0L) =
        CategoryRuleResponse(
            categoryRuleId = this[CategoryRules.categoryRuleId].toString(),
            name = this[CategoryRules.name],
            keywords = this[CategoryRules.keywords].split(",").map { it.trim() }.filter { it.isNotEmpty() },
            isDefault = this[CategoryRules.isDefault],
            sortOrder = this[CategoryRules.sortOrder],
            articleCount = articleCount,
        )

    private fun ResultRow.toSourceResponse() =
        SourceResponse(
            sourceId = this[Sources.sourceId].toString(),
            name = this[Sources.name],
            rssUrl = this[Sources.rssUrl],
            siteUrl = this[Sources.siteUrl],
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
                    category = row[Articles.ruleCategory] ?: "ネタ・その他",
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
