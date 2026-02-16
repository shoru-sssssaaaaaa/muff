# MUFF

2chまとめサイトの記事を快適に読むためのリーダーアプリ。iOS アプリ + Kotlin バックエンド + Next.js 管理画面のモノレポ構成。

## プロジェクト構成

```
muff/
├── backend/          # Kotlin/Ktor API サーバー
├── frontend/         # Next.js 管理ダッシュボード
├── ios/              # SwiftUI iOS アプリ
├── docs/             # PRD・技術設計書
└── .github/workflows # CI (GitHub Actions)
```

## 技術スタック

### Backend (`backend/`)

| 項目 | 技術 |
|------|------|
| 言語 | Kotlin 2.1 / JVM 21 |
| フレームワーク | Ktor 3.0 |
| ORM | Exposed 0.57 |
| データベース | PostgreSQL 16 |
| コネクションプール | HikariCP |
| RSS パーサー | ROME 2.1 |
| シリアライゼーション | kotlinx.serialization |
| API ドキュメント | OpenAPI / Swagger |
| テスト | Ktor Test Host + H2 |
| ビルド | Gradle (Shadow JAR) |
| コンテナ | Docker (Eclipse Temurin 21) |

### Frontend (`frontend/`)

| 項目 | 技術 |
|------|------|
| フレームワーク | Next.js 16 (App Router) |
| 言語 | TypeScript 5 |
| UI | Tailwind CSS 4 + shadcn/ui |
| データ取得 | TanStack React Query |
| テーマ | next-themes |
| リンター | ESLint 9 (eslint-config-next) |

### iOS (`ios/`)

| 項目 | 技術 |
|------|------|
| 言語 | Swift 6.0 |
| UI | SwiftUI |
| 最小 OS | iOS 17.0 |
| DB | GRDB.swift |
| 画像 | Nuke / NukeUI |
| RSS | FeedKit |
| プロジェクト生成 | XcodeGen (`project.yml`) |

## セットアップ

### 前提条件

- **Backend**: JDK 21, Docker (PostgreSQL 用)
- **Frontend**: Node.js 20+
- **iOS**: Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen)

### Backend

```bash
# PostgreSQL を起動
cd backend
docker compose up -d db

# サーバー起動 (localhost:8080)
./gradlew run
```

環境変数で設定をオーバーライド可能:

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `DATABASE_URL` | `jdbc:postgresql://localhost:5432/muff` | DB 接続先 |
| `DATABASE_USER` | `muff` | DB ユーザー |
| `DATABASE_PASSWORD` | `muff` | DB パスワード |
| `PORT` | `8080` | API ポート |
| `RSS_POLLING_INTERVAL_MINUTES` | `10` | RSS 取得間隔 (分) |
| `POPULARITY_AGGREGATION_INTERVAL_MINUTES` | `30` | 人気集計間隔 (分) |

Docker で全体を起動する場合:

```bash
cd backend
docker compose up -d
```

### Frontend

```bash
cd frontend
npm install
npm run dev     # localhost:3000 で起動
```

### iOS

```bash
cd ios/MUFF
xcodegen generate   # project.yml から .xcodeproj を生成
open MUFF.xcodeproj
```

Xcode でビルド・実行。`.xcodeproj` は `.gitignore` に含まれているため、clone 後は毎回 `xcodegen generate` が必要。

## 開発

### リンター

```bash
# Frontend の ESLint
npm run lint --prefix frontend
```

### Pre-commit フック

husky + lint-staged で、frontend の `.ts`/`.tsx` ファイルがステージングされた際に自動で lint が実行される。

```bash
# 初回セットアップ (npm install で自動実行)
npm install
```

### テスト

```bash
# Backend
cd backend && ./gradlew test

# Frontend
cd frontend && npm run build   # 型チェック + ビルド
```

### CI (GitHub Actions)

| ワークフロー | トリガー | 内容 |
|-------------|---------|------|
| `backend.yml` | `backend/` 変更時の push/PR | Gradle build + test (JDK 21) |
| `frontend.yml` | `frontend/` 変更時の push/PR | npm lint + build (Node.js 20) |

## API

バックエンド起動後、以下で Swagger UI にアクセス可能:

```
http://localhost:8080/swagger
```

主要エンドポイント:

| メソッド | パス | 説明 |
|---------|------|------|
| GET | `/catalog/sources` | ソース一覧 |
| GET | `/feed/new` | 新着記事フィード |
| GET | `/feed/popular` | 人気記事フィード |
| GET | `/feed/category/{category}` | カテゴリ別フィード |
| POST | `/events/open` | 記事閲覧イベント送信 |
| GET | `/admin/sources` | ソース管理 (Admin) |
| POST | `/admin/sources` | ソース追加 (Admin) |
| GET | `/admin/articles` | 記事一覧 (Admin) |
| GET | `/admin/popular` | 人気記事 (Admin) |

## iOS アプリ機能

- **ホーム**: 新着・人気・カテゴリ・フォローの各フィード
- **記事閲覧**: アプリ内 WebView / Reader モード
- **コンテンツフィルター**: キーワード非表示、リンク一覧非表示、リンク付き画像非表示、広告ブロック
- **ブックマーク**: フォルダ管理付き
- **検索**: 記事検索
- **設定**: ダークモード、サムネイル表示、既読表示、ソース管理、フォロー・ミュート管理、NG ワード、通知設定

## ドキュメント

- [PRD](docs/product_requirement.md)
- [技術設計書](docs/technical_design_document.md)
- [状態遷移仕様](docs/state_transition_spec.md)
