package com.muff.openapi

import io.swagger.v3.core.util.Yaml
import io.swagger.v3.oas.models.*
import io.swagger.v3.oas.models.info.Info
import io.swagger.v3.oas.models.media.*
import io.swagger.v3.oas.models.parameters.Parameter
import io.swagger.v3.oas.models.parameters.RequestBody
import io.swagger.v3.oas.models.responses.ApiResponse
import io.swagger.v3.oas.models.responses.ApiResponses
import io.swagger.v3.oas.models.servers.Server
import java.io.File

fun main(args: Array<String>) {
    val outputPath = args.firstOrNull() ?: error("Output file path required as argument")
    val yaml = Yaml.pretty(buildSpec())
    File(outputPath).apply {
        parentFile.mkdirs()
        writeText(yaml)
    }
}

fun buildSpec(): OpenAPI = OpenAPI().apply {
    info = Info().apply {
        title = "MUFF Backend API"
        description = "まとめサイト記事リーダー「MUFF」のバックエンドAPI（MVP）"
        version = "1.0.0"
    }
    servers = listOf(
        Server().apply { url = "http://localhost:8080"; description = "Local development" },
    )
    paths = buildPaths()
    components = buildComponents()
}

// ---------- Paths ----------

private fun buildPaths(): Paths = Paths().apply {
    addPathItem("/v1/catalog/sources", catalogSourcesPath())
    addPathItem("/v1/feed/new", feedNewPath())
    addPathItem("/v1/feed/popular", feedPopularPath())
    addPathItem("/v1/feed/category/{category}", feedCategoryPath())
    addPathItem("/v1/events/open", eventsOpenPath())
}

private fun catalogSourcesPath() = PathItem().apply {
    get = Operation().apply {
        tags = listOf("Catalog")
        summary = "公式ソース一覧を取得"
        description = "ステータスがactiveの公式RSSソース一覧を返す"
        operationId = "getSources"
        responses = ApiResponses().apply {
            addApiResponse("200", ApiResponse().apply {
                description = "ソース一覧"
                content = Content().addMediaType("application/json", MediaType().apply {
                    schema = ArraySchema().items(Schema<Any>().`$ref`("#/components/schemas/SourceResponse"))
                })
            })
        }
    }
}

private fun feedNewPath() = PathItem().apply {
    get = Operation().apply {
        tags = listOf("Feed")
        summary = "新着フィードを取得"
        description = "公開日時の降順で記事一覧を返す。カーソルベースのページネーション対応。"
        operationId = "getNewFeed"
        parameters = listOf(cursorParam(), limitParam())
        responses = feedResponses("記事一覧")
    }
}

private fun feedPopularPath() = PathItem().apply {
    get = Operation().apply {
        tags = listOf("Feed")
        summary = "人気フィードを取得"
        description = "最新の30分バケットにおけるopen数の降順で記事一覧を返す。全ユーザー横断の集計。view_count付き。"
        operationId = "getPopularFeed"
        parameters = listOf(limitParam())
        responses = feedResponses("人気記事一覧")
    }
}

private fun feedCategoryPath() = PathItem().apply {
    get = Operation().apply {
        tags = listOf("Feed")
        summary = "カテゴリ別フィードを取得"
        description = "指定カテゴリの記事を公開日時の降順で返す。カーソルベースのページネーション対応。"
        operationId = "getCategoryFeed"
        parameters = listOf(
            Parameter().apply {
                name = "category"
                `in` = "path"
                required = true
                description = "カテゴリ名（例: news, sports, game）"
                schema = StringSchema()
            },
            cursorParam(),
            limitParam(),
        )
        responses = feedResponses("カテゴリ別記事一覧")
    }
}

private fun eventsOpenPath() = PathItem().apply {
    post = Operation().apply {
        tags = listOf("Events")
        summary = "記事openイベントを送信"
        description = "クライアントが記事を開いた際にイベントを送信する。人気ランキングの集計に使用される。"
        operationId = "postOpenEvent"
        requestBody = RequestBody().apply {
            required = true
            description = "openイベント情報"
            content = Content().addMediaType("application/json", MediaType().apply {
                schema = Schema<Any>().`$ref`("#/components/schemas/OpenEventRequest")
            })
        }
        responses = ApiResponses().apply {
            addApiResponse("201", ApiResponse().apply {
                description = "イベント記録成功"
            })
            addApiResponse("400", ApiResponse().apply {
                description = "不正なリクエスト（必須フィールド不足、日時フォーマット不正）"
                content = errorContent()
            })
        }
    }
}

// ---------- Shared parameters ----------

private fun cursorParam() = Parameter().apply {
    name = "cursor"
    `in` = "query"
    required = false
    description = "ページネーションカーソル（前回レスポンスの next_cursor）"
    schema = StringSchema()
}

private fun limitParam() = Parameter().apply {
    name = "limit"
    `in` = "query"
    required = false
    description = "取得件数（デフォルト: 20、最大: 50）"
    schema = IntegerSchema().apply {
        minimum = java.math.BigDecimal(1)
        maximum = java.math.BigDecimal(50)
        setDefault(20)
    }
}

private fun feedResponses(okDescription: String) = ApiResponses().apply {
    addApiResponse("200", ApiResponse().apply {
        description = okDescription
        content = Content().addMediaType("application/json", MediaType().apply {
            schema = Schema<Any>().`$ref`("#/components/schemas/FeedResponse")
        })
    })
    addApiResponse("400", ApiResponse().apply {
        description = "不正なパラメータ"
        content = errorContent()
    })
}

private fun errorContent() = Content().addMediaType("application/json", MediaType().apply {
    schema = Schema<Any>().`$ref`("#/components/schemas/ErrorResponse")
})

// ---------- Components ----------

private fun buildComponents() = Components().apply {
    schemas = linkedMapOf(
        "SourceResponse" to ObjectSchema().apply {
            description = "公式RSSソース情報"
            addProperty("source_id", StringSchema().apply { description = "ソースID (UUID)" })
            addProperty("name", StringSchema().apply { description = "サイト名" })
            addProperty("rss_url", StringSchema().apply { description = "RSS URL" })
            addProperty("site_url", StringSchema().apply { description = "サイトURL" })
            addProperty("default_category", StringSchema().apply { description = "デフォルトカテゴリ" })
            addProperty("status", StringSchema().apply { description = "ステータス"; enum = listOf("active", "inactive") })
            required = listOf("source_id", "name", "rss_url", "site_url", "default_category", "status")
        },
        "ArticleResponse" to ObjectSchema().apply {
            description = "記事カード情報"
            addProperty("article_id", StringSchema().apply { description = "記事ID (UUID)" })
            addProperty("source_id", StringSchema().apply { description = "ソースID (UUID)" })
            addProperty("source_name", StringSchema().apply { description = "サイト名" })
            addProperty("title", StringSchema().apply { description = "記事タイトル" })
            addProperty("url", StringSchema().apply { description = "記事URL (canonical)" })
            addProperty("published_at", StringSchema().apply { description = "公開日時 (ISO 8601)"; format = "date-time" })
            addProperty("thumbnail_url", StringSchema().apply { description = "サムネイルURL"; nullable = true })
            addProperty("category", StringSchema().apply { description = "カテゴリ" })
            addProperty("view_count", IntegerSchema().apply { description = "閲覧数（人気フィードのみ）"; nullable = true })
            required = listOf("article_id", "source_id", "source_name", "title", "url", "published_at", "category")
        },
        "FeedResponse" to ObjectSchema().apply {
            description = "フィードレスポンス（ページネーション付き）"
            addProperty("items", ArraySchema().apply {
                description = "記事一覧"
                items = Schema<Any>().`$ref`("#/components/schemas/ArticleResponse")
            })
            addProperty("next_cursor", StringSchema().apply {
                description = "次ページのカーソル（最終ページの場合はnull）"
                nullable = true
            })
            required = listOf("items")
        },
        "OpenEventRequest" to ObjectSchema().apply {
            description = "記事openイベント"
            addProperty("article_url", StringSchema().apply { description = "記事URL" })
            addProperty("article_id", StringSchema().apply { description = "記事ID (UUID、任意)"; nullable = true })
            addProperty("occurred_at", StringSchema().apply { description = "発生日時 (ISO 8601)"; format = "date-time" })
            addProperty("anon_device_id_hash", StringSchema().apply { description = "匿名デバイスIDのハッシュ" })
            addProperty("app_version", StringSchema().apply { description = "アプリバージョン" })
            required = listOf("article_url", "occurred_at", "anon_device_id_hash", "app_version")
        },
        "ErrorResponse" to ObjectSchema().apply {
            description = "エラーレスポンス"
            addProperty("error", StringSchema().apply { description = "エラーコード" })
            addProperty("message", StringSchema().apply { description = "エラーメッセージ" })
            required = listOf("error", "message")
        },
    )
}
