import Foundation
import WebKit

@MainActor
final class AdBlocker {
    static let shared = AdBlocker()

    private(set) var ruleList: WKContentRuleList?
    private var isCompiled = false

    private init() {
        Task { await compile() }
    }

    private func compile() async {
        guard !isCompiled else { return }
        isCompiled = true

        do {
            ruleList = try await WKContentRuleListStore.default()
                .compileContentRuleList(forIdentifier: "muff-adblock", encodedContentRuleList: Self.rules)
        } catch {
            print("AdBlocker: failed to compile rules – \(error.localizedDescription)")
        }
    }

    // Safari Content Blocker format JSON rules
    // Only blocks third-party ad network resources (scripts/iframes/images).
    // CSS-based hiding and analytics blocking are intentionally omitted
    // to avoid breaking site functionality and triggering anti-adblock scripts.
    private static let rules: String = {
        let entries: [[String: Any]] = [
            // --- Ad-serving networks (third-party only) ---
            adRule(url: "googlesyndication\\.com"),
            adRule(url: "googleadservices\\.com"),
            adRule(url: "doubleclick\\.net"),
            adRule(url: "adnxs\\.com"),
            adRule(url: "amazon-adsystem\\.com"),
            adRule(url: "criteo\\.com"),
            adRule(url: "criteo\\.net"),
            adRule(url: "outbrain\\.com"),
            adRule(url: "taboola\\.com"),
            adRule(url: "microad\\.net"),
            adRule(url: "microad\\.co\\.jp"),
            adRule(url: "i-mobile\\.co\\.jp"),
            adRule(url: "ad\\.nend\\.net"),
            adRule(url: "impact-ad\\.jp"),
            adRule(url: "adstir\\.com"),
            adRule(url: "ad-stir\\.com"),
            adRule(url: "fluct\\.jp"),
            adRule(url: "geniee\\.jp"),
            adRule(url: "yieldone\\.com"),
            adRule(url: "logly\\.co\\.jp"),
            adRule(url: "ad2iction\\.com"),
            adRule(url: "ad-generation\\.jp"),
            adRule(url: "bidswitch\\.net"),
            adRule(url: "openx\\.net"),
            adRule(url: "pubmatic\\.com"),
            adRule(url: "rubiconproject\\.com"),
            adRule(url: "casalemedia\\.com"),
            adRule(url: "socdm\\.com"),
            adRule(url: "zucks\\.net"),
            adRule(url: "yads\\.yahoo\\.co\\.jp"),
            adRule(url: "yimg\\.jp\\/images\\/ads"),
            adRule(url: "popin\\.cc"),
            adRule(url: "reemo\\.io"),
            adRule(url: "aladsp\\.com"),
            adRule(url: "adingo\\.jp"),
            adRule(url: "ad-track\\.jp"),
            adRule(url: "adsrvr\\.org"),
            adRule(url: "shinobi\\.jp"),
            adRule(url: "gmossp-sp\\.jp"),
            adRule(url: "amoad\\.com"),
            adRule(url: "adlantis\\.jp"),
            adRule(url: "speee-ad"),
            adRule(url: "uzou\\.jp"),
            adRule(url: "compass-fit\\.jp"),
            adRule(url: "ladsp\\.com"),
            adRule(url: "ad\\.prdsrv\\.com"),
            adRule(url: "blogroll\\.livedoor\\.net"),
        ]

        let data = try! JSONSerialization.data(withJSONObject: entries, options: [])
        return String(data: data, encoding: .utf8)!
    }()

    /// Block third-party ad resources only (script, image, raw).
    /// Using third-party + resource-type filters avoids breaking site
    /// functionality and reduces anti-adblock detection.
    private static func adRule(url pattern: String) -> [String: Any] {
        [
            "trigger": [
                "url-filter": pattern,
                "load-type": ["third-party"],
                "resource-type": ["script", "image", "raw", "document"],
            ],
            "action": ["type": "block"],
        ]
    }
}
