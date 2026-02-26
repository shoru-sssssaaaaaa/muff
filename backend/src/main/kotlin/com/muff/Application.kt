package com.muff

import com.muff.config.AppConfig
import com.muff.db.DatabaseFactory
import com.muff.db.tables.CategoryRules
import com.muff.job.ScheduledJobs
import com.muff.plugins.configureAppAttest
import com.muff.plugins.configureCors
import com.muff.plugins.configureRouting
import com.muff.plugins.configureSerialization
import com.muff.plugins.configureStatusPages
import com.muff.service.AppAttestService
import com.muff.service.CategoryClassifier
import com.muff.service.FeedService
import com.muff.service.PopularityService
import com.muff.service.RssPollingService
import io.ktor.server.application.Application
import io.ktor.server.application.ApplicationStopped
import kotlinx.datetime.Clock
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction
import java.util.UUID

fun main(args: Array<String>) {
    io.ktor.server.netty.EngineMain.main(args)
}

fun Application.module() {
    val appConfig = AppConfig.load(environment)

    // Database
    DatabaseFactory.init(appConfig.database)

    // Seed category rules if table is empty
    seedCategoryRules()

    // Services
    val categoryClassifier = CategoryClassifier()
    categoryClassifier.reloadRules()

    val feedService = FeedService(categoryClassifier)
    val rssPollingService = RssPollingService(categoryClassifier)
    val popularityService = PopularityService()
    val attestService = AppAttestService(appConfig.appAttest)

    // Plugins
    configureCors(appConfig.cors)
    configureSerialization()
    configureStatusPages()
    configureAppAttest(appConfig.appAttest, attestService)
    configureRouting(feedService, categoryClassifier, rssPollingService, attestService)

    // Reclassify existing articles with latest rules
    rssPollingService.reclassifyAll()

    // Scheduled Jobs
    val jobs =
        ScheduledJobs(
            rssPollingService = rssPollingService,
            popularityService = popularityService,
            attestService = attestService,
            feedService = feedService,
            rssIntervalMinutes = appConfig.jobs.rssPollingIntervalMinutes,
            popularityIntervalMinutes = appConfig.jobs.popularityAggregationIntervalMinutes,
        )
    jobs.start()

    monitor.subscribe(ApplicationStopped) {
        jobs.stop()
    }
}

private fun seedCategoryRules() {
    transaction {
        val existingNames =
            CategoryRules.selectAll()
                .map { it[CategoryRules.name] }
                .toSet()

        val now = Clock.System.now()
        val seeds =
            listOf(
                SeedRule(
                    "AI",
                    "ai,人工知能,機械学習,deep learning,ディープラーニング,llm,大規模言語モデル," +
                        "chatgpt,gpt,claude,gemini,生成ai,generative ai,openai,transformer,rag," +
                        "langchain,embedding,ファインチューニング,fine-tuning,stable diffusion,midjourney,copilot",
                    sortOrder = 0,
                ),
                SeedRule(
                    "ビジネス",
                    "資金調達,funding,ipo,決算,売上,revenue,スタートアップ,startup,起業,経営," +
                        "マネジメント,management,m&a,買収,acquisition,投資,investment," +
                        "マーケティング,marketing,プロダクト,product,採用,hiring,リストラ,layoff",
                    sortOrder = 1,
                ),
                SeedRule(
                    "仕事",
                    "仕事,働き方,転職,就職,キャリア,career,リモートワーク,テレワーク,remote work,副業," +
                        "フリーランス,freelance,給与,年収,salary,労働,残業,ワークライフバランス,退職,人事",
                    sortOrder = 2,
                ),
                SeedRule(
                    "ニュース",
                    "速報,breaking,発表,announce,リリース,release,公開,launched,開始,提供開始,新サービス," +
                        "アップデート,update,バージョン,version,廃止,終了,サービス終了,障害,復旧",
                    sortOrder = 3,
                ),
                SeedRule(
                    "エンタメ",
                    "ゲーム,game,gaming,アニメ,anime,漫画,manga,映画,movie,ドラマ,音楽,music," +
                        "youtube,配信,streaming,vtuber,エンタメ,entertainment,推し,コンテンツ",
                    sortOrder = 4,
                ),
                SeedRule(
                    "経済",
                    "経済,economy,gdp,インフレ,inflation,円安,円高,為替,金利,利上げ,利下げ,日銀,fed," +
                        "株価,株式,stock,市場,market,景気,貿易,関税,tariff,金融,finance",
                    sortOrder = 5,
                ),
                SeedRule(
                    "テック",
                    "apple,google,meta,microsoft,amazon,nvidia,tesla,openai,スマホ,smartphone," +
                        "半導体,semiconductor,chip,量子コンピュータ,quantum,5g,6g,iot,ロボット,robot,自動運転," +
                        "vr,ar,メタバース,metaverse,ウェアラブル,wearable,ev,電気自動車,宇宙,space,衛星,satellite",
                    sortOrder = 6,
                ),
                SeedRule(
                    "スポーツ",
                    "スポーツ,sports,野球,baseball,サッカー,soccer,football,バスケ,basketball,nba," +
                        "テニス,tennis,オリンピック,olympic,ワールドカップ,world cup,大谷,mlb,プロ野球," +
                        "jリーグ,j-league,ゴルフ,golf,ラグビー,rugby,格闘技,ボクシング",
                    sortOrder = 7,
                ),
                SeedRule(
                    "政治",
                    "政治,politics,政府,government,国会,国政,選挙,election,投票,vote,与党,野党," +
                        "首相,大統領,president,総理,内閣,cabinet,法案,法律,law,規制,regulation,条例," +
                        "外交,diplomacy,安全保障,防衛,軍事,憲法,constitution,議員,政党,自民党,民主党",
                    sortOrder = 8,
                ),
                SeedRule(
                    "社会",
                    "事件,事故,裁判,逮捕,容疑,被害,犯罪,詐欺,殺人,窃盗,暴行," +
                        "社会問題,少子化,高齢化,人口減少,格差,貧困,差別,ハラスメント," +
                        "炎上,批判,謝罪,不祥事,問題視,物議",
                    sortOrder = 9,
                ),
                SeedRule(
                    "国際",
                    "海外,中国,韓国,北朝鮮,アメリカ,ロシア,ウクライナ,台湾,eu,イスラエル," +
                        "戦争,紛争,制裁,国連,nato,g7,g20,サミット,大使,領土," +
                        "移民,難民,テロ,国境,条約,国際",
                    sortOrder = 10,
                ),
                SeedRule(
                    "科学",
                    "研究,論文,発見,実験,科学,science,物理,化学,生物,医学,医療," +
                        "ノーベル賞,学術,大学,教授,博士,理研,nasa,jaxa," +
                        "新薬,治療,ワクチン,臨床,遺伝子,dna,ips細胞",
                    sortOrder = 11,
                ),
                SeedRule(
                    "生活",
                    "料理,レシピ,グルメ,食事,健康,ダイエット,美容,ファッション," +
                        "住宅,不動産,マンション,一戸建て,引っ越し,インテリア," +
                        "節約,家計,ポイント,ふるさと納税,育児,子育て,教育,学校,受験," +
                        "ライフハック,生活,暮らし,家事,掃除,収納",
                    sortOrder = 12,
                ),
                SeedRule(
                    "投資・マネー",
                    "投資信託,nisa,ideco,積立,配当,優待,信用取引,デイトレ," +
                        "仮想通貨,暗号資産,ビットコイン,bitcoin,イーサリアム,ethereum,crypto," +
                        "fx,為替トレード,資産運用,老後資金,家計管理,節税,確定申告," +
                        "不動産投資,利回り,ポートフォリオ",
                    sortOrder = 13,
                ),
                SeedRule(
                    "IT・開発",
                    "プログラミング,programming,エンジニア,engineer,開発者,developer," +
                        "python,javascript,typescript,rust,go,java,kotlin,swift,react,vue," +
                        "github,oss,オープンソース,linux,docker,kubernetes,aws,gcp,azure," +
                        "api,データベース,セキュリティ,脆弱性,サイバー攻撃,インフラ,saas",
                    sortOrder = 14,
                ),
                SeedRule(
                    "車・乗り物",
                    "自動車,車,カー,トヨタ,ホンダ,日産,マツダ,スバル,スズキ,ダイハツ," +
                        "ベンツ,bmw,テスラ,フェラーリ,ポルシェ," +
                        "バイク,オートバイ,二輪,鉄道,電車,新幹線,jr,私鉄," +
                        "航空,飛行機,空港,ana,jal,ドライブ,ツーリング,車検",
                    sortOrder = 15,
                ),
                SeedRule(
                    "ネタ・その他",
                    "ネタ,話題,トレンド,面白い,興味深い",
                    isDefault = true,
                    sortOrder = 99,
                ),
            )

        val newSeeds = seeds.filter { it.name !in existingNames }
        for (seed in newSeeds) {
            CategoryRules.insert {
                it[categoryRuleId] = UUID.randomUUID()
                it[name] = seed.name
                it[keywords] = seed.keywords
                it[isDefault] = seed.isDefault
                it[sortOrder] = seed.sortOrder
                it[createdAt] = now
            }
        }
    }
}

private data class SeedRule(
    val name: String,
    val keywords: String,
    val isDefault: Boolean = false,
    val sortOrder: Int,
)
