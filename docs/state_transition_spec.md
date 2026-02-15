# MUFF Navigation / State Transition Spec v1.0 (iOS / MVP)

目的：実装・QA・チケット化で迷いが出ないように、画面遷移・戻る挙動・モーダル・外部遷移・エラー時の扱いを確定する。

前提：PRD v1.1 / TDD v1.1 / 画面仕様 v1.1 と整合（記事タップはアプリ内WebView標準、外部ブラウザは「元記事を見る」のみ、Readerは任意で失敗時フォールバック、人気はサーバ集計、ユーザー追加RSSの壊れ検知はクライアント責務）。

⸻

1. ナビゲーション構造（全体）

1.1 ルート構造
	•	Root = Tab Bar（各タブは独立したNavigation Stackを持つ）
	•	Tab1: Home（内部にTop Tabs：新着 / 人気 / カテゴリ / フォロー）
	•	Tab2: Search
	•	Tab3: Bookmarks
	•	Tab4: Settings

1.2 スタック保持
	•	タブ切替で画面を破棄しない（各タブのスタックを保持）
	•	可能ならTop Tabs内のスクロール位置も保持（推奨）

⸻

2. 画面ID（実装・計測・QA共通）
	•	ONB-01 Welcome（初回のみ）
	•	HOM-00 Home Container（Top Tabs）
	•	HOM-01 New Feed
	•	HOM-02 Popular Feed
	•	HOM-03 Category List
	•	HOM-04 Category Feed
	•	HOM-05 Follow Feed
	•	ART-01 Article Detail（Web/Reader）
	•	SEA-01 Search（結果込み）
	•	BKM-01 Bookmark Folders
	•	BKM-02 Bookmark Items（Folder）
	•	SET-01 Settings Top
	•	SET-02 Reader Settings
	•	SET-03 Follow Manage
	•	SET-04 Mute Manage
	•	SET-05 NG Word Manage
	•	SET-06 Notifications Settings
	•	SET-07 Sources List
	•	SET-08 Add RSS
	•	SET-09 Cache & Logs（任意）

⸻

3. 状態遷移（全体フロー）

3.1 App Launch → 初回起動

App Launch
  ├─ First launch? yes → ONB-01 Welcome → (Continue) → HOM-00 Home
  └─ First launch? no  → HOM-00 Home

戻る
	•	ONB-01：戻るボタンなし（OSの終了動作のみ）

⸻

3.2 Home タブ（Top Tabs）

HOM-00 Home Container
  ├─ TopTab: New      → HOM-01 New Feed
  ├─ TopTab: Popular  → HOM-02 Popular Feed
  ├─ TopTab: Category → HOM-03 Category List → (tap category) → HOM-04 Category Feed
  └─ TopTab: Follow   → HOM-05 Follow Feed → (Manage) → SET-03 Follow Manage (push)

戻る
	•	HOM-04 Back → HOM-03
	•	SET-03 Back → HOM-05

保持（推奨）
	•	TopTab切替時に各フィードのスクロール位置・カーソル状態を保持

⸻

3.3 記事詳細への遷移（共通）

Any list screen (HOM-01/02/04/05, SEA-01, BKM-02)
  └─ tap Article Card → ART-01 Article Detail (push)

重要（標準表示）
	•	ART-01はアプリ内WebView表示が標準（Web Mode）。
	•	外部ブラウザは ART-01 内の「元記事を見る」タップでのみ起動。

戻る
	•	ART-01 Back → 元のリスト画面へ（スクロール位置復元）

⸻

3.4 記事詳細内の状態遷移（Web/Reader/Bookmark/External）

ART-01 Article Detail
  ├─ Default: Web Mode (in-app WebView)
  ├─ Tap [Reader] → Reader Mode
  │     ├─ Success → Reader View render
  │     └─ Fail → auto fallback to Web Mode (+ optional toast)
  ├─ Tap [Bookmark] → SHEET-01 Folder Picker → (select) → dismiss
  ├─ Tap [Reader Settings] → SHEET-02 Reader Settings → dismiss (optional)
  └─ Tap [元記事を見る] → External Browser (system default)

スワイプで次/前の記事
	•	ART-01 内で左右スワイプ → 同一フィード文脈の前後記事をロード
	•	仕様：
	•	スワイプ先の記事表示開始時点で既読付与／openイベント送信
	•	Backで戻る先は最初に開いたリスト画面のまま固定（迷子防止）

⸻

3.5 Search タブ

SEA-01 Search
  ├─ enter query → results shown (same screen)
  ├─ tap article → ART-01 (push)
  └─ tap [Follow keyword +] → SHEET-03 Keyword Add → dismiss

戻る
	•	ART-01 Back → SEA-01（検索結果状態を保持）

⸻

3.6 Bookmarks タブ

BKM-01 Bookmark Folders
  ├─ tap folder → BKM-02 Folder Items (push)
  ├─ + → SHEET-04 New Folder → dismiss
  └─ long-press folder → context menu (rename/delete)

BKM-02 Folder Items
  └─ tap article → ART-01 (push)

戻る
	•	BKM-02 Back → BKM-01

⸻

3.7 Settings タブ

SET-01 Settings Top
  ├─ Reader settings → SET-02 (push)
  ├─ Follow manage   → SET-03 (push)
  ├─ Mute manage     → SET-04 (push)
  ├─ NG words        → SET-05 (push)
  ├─ Notifications   → SET-06 (push)
  ├─ Sources         → SET-07 (push)
  │     └─ + Add RSS → SET-08 (push)
  └─ Cache & Logs    → SET-09 (push, optional)

戻る
	•	各設定画面 Back → SET-01

⸻

4. モーダル（Sheet/Alert）定義

SHEET-01 Folder Picker（ブックマーク保存先選択）
	•	発火：ART-01 の Bookmark
	•	アクション：
	•	フォルダ選択→保存→dismiss+toast
	•	+ 新規フォルダ → SHEET-04 を重ねる or 画面内で作成
	•	Cancel→dismiss

SHEET-02 Reader Settings（記事内の簡易設定）
	•	発火：ART-01（任意）
	•	即時反映、dismiss

SHEET-03 Keyword Add（キーワード追加）
	•	発火：SEA-01 または SET-03
	•	入力→保存→dismiss

SHEET-04 New Folder（新規フォルダ作成）
	•	発火：BKM-01 の + または SHEET-01 の +
	•	入力→作成→dismiss

ALERT-01 Folder Delete Confirm
	•	フォルダ削除の確認（中身も削除される旨）

ALERT-02 Add RSS Failure
	•	RSS追加/検証失敗（原因 + 再試行）

⸻

5. 戻る挙動ルール（確定）
	1.	タブ切替は状態保持

	•	タブを跨いで戻ってきても直前の階層を保持

	2.	Backは直前画面へ

	•	ART-01 Backは常に “最初に開いたリスト” へ
	•	スワイプで別記事へ移動してもBack先は変えない

	3.	Sheetはdismissで復帰

	•	モーダル内保存→dismiss→元画面状態を維持

⸻

6. 外部遷移 / Deep Link

6.1 外部ブラウザ
	•	ART-01 の「元記事を見る」→ 端末のデフォルトブラウザを起動

6.2 Deep Link（将来予約 / MVP非必須）
	•	muff://article?url=...
	•	muff://category/news
	•	muff://settings/sources

⸻

7. エラー時の扱い（遷移なしが原則）

7.1 フィード読み込み失敗（Home/Search）
	•	同一画面内でエラー表示（遷移しない）
	•	再試行ボタン
	•	キャッシュがあればキャッシュ表示＋オフライン表示

7.2 RSS追加失敗（SET-08）
	•	入力保持したまま画面内にエラー表示
	•	付加的に ALERT-02 を使って良い

7.3 Reader抽出失敗（ART-01）
	•	画面遷移なし
	•	自動フォールバック→Web Mode
	•	任意でトースト表示

7.4 ユーザー追加RSSの取得失敗（毎回知らせる）
	•	SET-07 Sources List で
	•	エラーバッジ（該当ソース）
	•	インラインバナー（再試行）

⸻

8. 整合チェック（TDD/画面仕様との一致）
	•	記事タップ→アプリ内WebView（標準） ✅
	•	外部ブラウザは「元記事を見る」のみ ✅
	•	Readerは任意ON/OFF、失敗フォールバック ✅
	•	人気はサーバ集計（全ユーザー横断open数） ✅
	•	ユーザー追加RSSの壊れ検知はクライアント責務 ✅

⸻

9. 実装時の注意点（衝突回避）
	•	記事画面の左右スワイプとWebViewの横スクロール競合
	•	スワイプ領域を画面端に限定する、またはジェスチャ優先度調整
	•	タブ切替時のメモリ
	•	リストはキャッシュしつつ、画像は適切に破棄/再ロード
	•	Back復帰時のスクロール位置
	•	ListはscrollAnchorやcontentOffsetを保存して復帰