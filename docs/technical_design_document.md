# MUFF Technical Design Document (TDD) v1.1 — 最終版

対象：iOS（MVP先行）

方針：一覧の読みやすさを最優先に、発見（人気/フォロー）と任意のリーダーモードで差別化する。

⸻

0. 改訂履歴
	•	v1.1
	•	記事表示方針を明文化：標準はアプリ内Web表示（WebView）／Readerは任意の抽出表示
	•	人気ランキングは サーバ集計（全ユーザー横断のopen数） を前提とする
	•	ユーザー追加RSSの壊れ検知はクライアント責務に一本化（/health APIはMVPから除外）

⸻

1. 目的とスコープ

1.1 目的
	•	まとめサイト記事を「速く・読みやすく・迷わず」読めるiOSアプリをMVPとしてリリースする。
	•	ユーザーが自分向けに整える（フォロー/ミュート/NGワード）ことで継続利用を促す。

1.2 MVPスコープ（機能）
	•	Home：新着 / 人気 / カテゴリ / フォロー
	•	記事カード：大きめサムネ（ON/OFF可）、カテゴリ/サイト名/タイトル/閲覧数（数値）
	•	既読：記事オープン時に付与。薄表示、設定で折りたたみ/非表示
	•	記事閲覧（標準）：アプリ内WebViewで元サイト表示
	•	Readerモード（任意）：ユーザー操作でON→HTMLから本文抽出表示（失敗時はWebへフォールバック）
	•	“元記事を見る”：端末のデフォルトブラウザ起動
	•	ブックマーク：1階層フォルダ、保存順ソート
	•	履歴：メタのみ保持（HTML保存なし）、30日超は段階削除（明示不要）
	•	ミュート：カテゴリ/サイト（24h解除）
	•	注意ラベル：ユーザーNGワードによりタイトル一致→ラベル付与（自動非表示はしない）
	•	通知：デフォOFF、最大1日1回（フォロー新着/キーワード/朝ダイジェスト）
	•	広告：一般SDK、一覧最下部のみ
	•	テレメトリ：クラッシュ＋主要イベント＋スクロール深度

⸻

2. 非機能要件

2.1 UX/性能
	•	フィード初期表示：キャッシュ優先で体感高速
	•	スクロール：60fps優先（画像遅延ロード、prefetch）
	•	記事表示：Web表示は即時、Reader抽出は非同期で待ち時間最小化

2.2 安定性
	•	RSS取得失敗・抽出失敗でもアプリが壊れない（フォールバック/再試行）
	•	ブロック・不達は放置可。ただし 後から気づけるログ を保持

2.3 プライバシー
	•	個人特定を避けた匿名ID（ローテーション推奨）
	•	SDKは最小構成（広告/計測ともに）

⸻

3. アーキテクチャ概要（推奨：軽量バックエンド）

3.1 なぜサーバが必要か
	•	「人気」タブは 全ユーザー横断のopen数ランキング を表示する必要があるため、MVPでもサーバで集計する。

3.2 コンポーネント
	•	iOS Client：表示・設定・ローカル保存・ユーザー追加RSSの健全性判定
	•	Backend（Minimal）：
	•	公式ソース（初期30）RSS集約
	•	記事メタ配信（新着/カテゴリ）
	•	openイベント収集
	•	30分バケットで人気集計

重要：ユーザー追加RSSの壊れ検知は クライアント が責務（運用コスト低減）

⸻

4. クライアント設計（iOS）

4.1 技術スタック
	•	Swift / SwiftUI（またはUIKit+SwiftUI）
	•	Concurrency：async/await
	•	ローカルDB：SQLite（GRDB推奨）または CoreData
	•	画像：URLCache + Disk Cache（またはNuke/SDWebImage等）

4.2 論理モジュール
	•	Feed（新着/人気/カテゴリ/フォロー）
	•	Article（WebView/Reader/Bookmark/SwipeNext）
	•	Sources（公式+ユーザー追加、健全性チェック）
	•	Bookmarks（フォルダ/保存順）
	•	History（メタ保存、30日超削除）
	•	Rules（Mute/NG words）
	•	Settings（表示/Reader/通知/既読扱い）
	•	Telemetry（イベントバッファ/送信）
	•	Ads（一覧最下部）

⸻

5. サーバ設計（Minimal Backend）

5.1 推奨構成
	•	API：REST（JSON）
	•	DB：PostgreSQL（マネージド）または DynamoDB
	•	Job：RSSポーリング、人気集計（30分）

5.2 データモデル（概念）

Source（公式カタログ）
	•	source_id, name, rss_url, site_url, default_category, status
	•	last_fetch_at, last_success_at, consecutive_failures

Article（RSS itemメタ）
	•	article_id, source_id, title, url(canonical), published_at
	•	thumbnail_url(optional), category, ingested_at

OpenEvent（集計用）
	•	event_id, article_id(or url), occurred_at, anon_device_id_hash, app_version

Popularity（集計結果）
	•	bucket_start_at, article_id, open_count

⸻

6. API設計（MVP）

6.1 認証
	•	MVP：ログインなし
	•	クライアントが anon_device_id を生成し、ハッシュ化して送信（定期ローテーション推奨）

6.2 エンドポイント

GET /v1/catalog/sources
	•	公式ソース一覧

GET /v1/feed/new?cursor=…&limit=…
	•	新着（published_at desc）

GET /v1/feed/popular?bucket=latest&limit=…
	•	人気（最新30分バケットのopen数 desc）

GET /v1/feed/category/{category}?cursor=…&limit=…
	•	カテゴリ別新着

POST /v1/events/open（必須）
	•	記事openイベント
	•	Body例：{ article_url, article_id?, occurred_at, anon_device_id_hash, app_version }

注：MVPでは /health 系は提供しない（ユーザー追加RSSはクライアント判定）

6.3 カーソル
	•	published_at + article_id をopaque cursor化（base64）

⸻

7. RSS取り込み（サーバ：公式ソースのみ）

7.1 ポーリング
	•	初期30：5〜10分間隔（運用で調整）
	•	RSS/Atom対応

7.2 正規化
	•	タイトル正規化（空白/絵文字/機種依存文字）
	•	URL正規化（可能ならトラッキングパラメータ除去）

7.3 サムネ
	•	RSSのmedia:thumbnail優先
	•	OGPはMVPでは「ある時だけ」/後回し可

7.4 公式ソースの障害検知
	•	consecutive_failuresで劣化検知、ログ化（運用者が確認）

⸻

8. ユーザー追加RSS（クライアント責務）

8.1 追加フロー
	•	ユーザーがRSS URLを直接入力
	•	カテゴリはユーザーが選択（必須）

8.2 健全性チェック（毎回知らせる）
	•	更新時にクライアントが取得→失敗したら 毎回 UIで明示
	•	Sources一覧にエラーバッジ
	•	画面上部にインラインバナー（再試行あり）

⸻

9. Readerモード設計（クライアント）

9.1 基本
	•	デフォルトOFF、ボタンでON/OFF（全体設定）
	•	抽出失敗時：自動フォールバック→Web表示
	•	“元記事を見る” リンクは常に表示（外部ブラウザ）

9.2 抽出方針
	•	WebViewで表示中にHTML取得（またはHTTP取得）
	•	Readability系（本文候補DOMのスコアリング）で抽出
	•	サニタイズ：script除去
	•	CSS適用：フォント/行間/画像非表示/ダーク

9.3 失敗判定例
	•	本文が短すぎる、段落が取れない等→失敗

⸻

10. 既読・履歴・ブックマーク

10.1 既読
	•	記事open時にURL基準で既読登録
	•	表示：薄表示、設定で折りたたみ/非表示

10.2 履歴
	•	メタのみ（URL/タイトル/サイト/日時）
	•	30日超は段階削除

10.3 ブックマーク
	•	フォルダ：1階層
	•	並び：保存順（新しい順）
	•	メモなし

⸻

11. フォロー・ミュート・注意ラベル

11.1 フォロー
	•	対象：カテゴリ/サイト/キーワード
	•	キーワードはタイトル一致（MVP）

11.2 ミュート
	•	対象：カテゴリ/サイト
	•	24h解除（disabled_until）

11.3 注意ラベル
	•	ユーザーNGワードがタイトル一致→注意ラベル
	•	自動非表示はしない

⸻

12. 通知（MVP）
	•	デフォOFF
	•	最大1日1回
	•	種類：フォロー新着/キーワード新着/朝ダイジェスト（任意）
	•	権限はユーザーがONにしたタイミングで要求

⸻

13. 広告
	•	一般広告SDK
	•	配置：Homeフィード最下部のみ
	•	設定画面/記事画面には置かない

⸻

14. テレメトリ

14.1 取得イベント（最低限）
	•	Crash
	•	ScreenView（Home subtab/Article/Search/Bookmarks/Settings）
	•	ArticleOpen（openイベント送信）
	•	ReaderToggle
	•	BookmarkAdd/Remove
	•	MuteAdd/Remove
	•	Search
	•	ScrollDepth（25/50/75/100%）

14.2 送信
	•	バッファリング→まとめ送信
	•	anon_device_id_hash（ローテーション推奨）

⸻

15. エラーハンドリング / 運用
	•	Feed取得失敗：キャッシュ表示→再試行
	•	Reader失敗：フォールバック（画面遷移なし）
	•	公式ソース障害：運用者ログで把握
	•	ユーザー追加RSS障害：UIで毎回通知

⸻

16. セキュリティ
	•	HTTPSのみ
	•	Reader抽出はサニタイズ必須（script除去）
	•	イベントAPIはレート制限/署名（最低限）

⸻

17. テスト戦略

17.1 Unit
	•	既読/折りたたみ/非表示
	•	ミュート/24h解除
	•	NGワードラベル
	•	ブックマーク（フォルダ/保存順）
	•	履歴削除（30日超）

17.2 Integration
	•	Feed→ArticleOpen→人気反映
	•	Reader成功/失敗フォールバック
	•	サムネON/OFF

17.3 E2E（最小）
	•	起動→新着→記事→既読→ブクマ→フォロー→通知設定

⸻

18. リリース計画
	•	Alpha：一覧UXとReader品質
	•	Beta：読みやすさ中心の改善
	•	v1.0：安定性/速度/UX優先で公開

⸻

19. 既知のリスクと対策
	•	Reader抽出品質：フォールバック + 失敗率計測 + 重点サイト改善
	•	人気の偏り：MVPは不正対策なし、後で重複open除外など
	•	RSSの多様性：公式30は運用ログで対応、ユーザー追加はUIで可視化
