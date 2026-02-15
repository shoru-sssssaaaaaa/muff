# MUFF Backend

まとめサイト記事リーダー「MUFF」の最小バックエンド。公式RSSソースの集約・記事メタ配信・人気ランキング集計を担う。

## 技術スタック

- Kotlin 2.1.0 / Ktor 3.0.3
- Exposed 0.57.0 (ORM)
- PostgreSQL / HikariCP
- Rome 2.1.0 (RSS/Atom パーサ)

## セットアップ

### 前提

- JDK 21+
- PostgreSQL

### データベース作成

```sql
CREATE DATABASE muff;
CREATE USER muff WITH PASSWORD 'muff';
GRANT ALL PRIVILEGES ON DATABASE muff TO muff;
```

### 設定

`src/main/resources/application.conf` (HOCON) で設定。環境変数で上書き可能。

| 環境変数 | デフォルト | 説明 |
|----------|-----------|------|
| `PORT` | 8080 | サーバポート |
| `DATABASE_URL` | jdbc:postgresql://localhost:5432/muff | DB接続URL |
| `DATABASE_USER` | muff | DBユーザー |
| `DATABASE_PASSWORD` | muff | DBパスワード |
| `DATABASE_MAX_POOL_SIZE` | 10 | コネクションプール最大数 |
| `RSS_POLLING_INTERVAL_MINUTES` | 10 | RSSポーリング間隔(分) |
| `POPULARITY_AGGREGATION_INTERVAL_MINUTES` | 30 | 人気集計間隔(分) |

### ビルド・起動（ローカル）

```bash
./gradlew build   # ビルド + テスト
./gradlew run     # サーバ起動 (port 8080)
```

### Docker で起動

```bash
docker compose up --build    # PostgreSQL + Backend を起動
docker compose down          # 停止
```

- Backend: http://localhost:8080
- Swagger UI: http://localhost:8080/swagger

### テスト

```bash
./gradlew test
```

テストはH2インメモリDBで実行されるため、PostgreSQL不要。

## API

| Method | Path | 説明 |
|--------|------|------|
| GET | `/v1/catalog/sources` | 公式ソース一覧 |
| GET | `/v1/feed/new?cursor=&limit=` | 新着フィード (published_at DESC) |
| GET | `/v1/feed/popular?limit=` | 人気フィード (最新30分バケット) |
| GET | `/v1/feed/category/{category}?cursor=&limit=` | カテゴリ別フィード |
| POST | `/v1/events/open` | 記事openイベント送信 |

### ページネーション

`cursor` パラメータによるカーソルベース。レスポンスの `next_cursor` を次のリクエストに渡す。`limit` のデフォルトは20、最大50。

### POST /v1/events/open リクエスト例

```json
{
  "article_url": "https://example.com/article/123",
  "article_id": "550e8400-e29b-41d4-a716-446655440000",
  "occurred_at": "2026-02-13T10:30:00Z",
  "anon_device_id_hash": "sha256hash",
  "app_version": "1.0.0"
}
```

## プロジェクト構成

```
src/main/kotlin/com/muff/
├── Application.kt           # エントリポイント
├── config/AppConfig.kt      # 設定読み込み
├── db/
│   ├── DatabaseFactory.kt   # DB接続・テーブル自動作成
│   └── tables/              # Exposed テーブル定義
├── model/
│   ├── ApiModels.kt         # リクエスト/レスポンス DTO
│   └── Cursor.kt            # カーソル encode/decode
├── plugins/                 # Ktor プラグイン設定
├── routes/                  # API ルートハンドラ
├── service/                 # ビジネスロジック
└── job/ScheduledJobs.kt     # 定期実行ジョブ
```

## バックグラウンドジョブ

| ジョブ | 間隔 | 内容 |
|--------|------|------|
| RSSポーリング | 10分 | 公式ソースのRSS取得・記事メタ保存 |
| 人気集計 | 30分 | OpenEventsを集計しPopularityBucketsへ書き込み |
