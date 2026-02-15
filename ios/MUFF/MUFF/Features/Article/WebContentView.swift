import SwiftUI
import WebKit

struct WebContentView: UIViewRepresentable {
    let url: String
    var searchTrigger: Int = 0
    var onFiltered: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let settings = AppSettings.shared

        if settings.adBlockEnabled, let ruleList = AdBlocker.shared.ruleList {
            config.userContentController.add(ruleList)
            context.coordinator.hasAdBlock = true
        }

        if settings.darkModeEnabled {
            let darkCSS = """
            var _ds=document.createElement('style');
            _ds.textContent='html{filter:invert(1) hue-rotate(180deg)}img,video,iframe,canvas,svg,[style*=background-image]{filter:invert(1) hue-rotate(180deg)}';
            document.documentElement.appendChild(_ds);
            """
            config.userContentController.addUserScript(
                WKUserScript(source: darkCSS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            )
        }

        let hasKeywords = !((try? AppDatabase.shared.contentFilterKeywords()) ?? []).isEmpty
        if hasKeywords || settings.hideLinkTables || settings.hideLinkedImages {
            let hideScript = WKUserScript(
                source: "document.documentElement.style.opacity='0.15';",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            config.userContentController.addUserScript(hideScript)
            context.coordinator.needsFiltering = true
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isFindInteractionEnabled = true
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        context.coordinator.onFiltered = onFiltered

        if let loadURL = URL(string: url) {
            context.coordinator.loadedURL = url
            webView.load(URLRequest(url: loadURL))
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.loadedURL != url, let newURL = URL(string: url) {
            context.coordinator.loadedURL = url
            webView.load(URLRequest(url: newURL))
        }

        if searchTrigger != context.coordinator.lastSearchTrigger {
            context.coordinator.lastSearchTrigger = searchTrigger
            if searchTrigger > 0 {
                webView.findInteraction?.presentFindNavigator(showingReplace: false)
            }
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        var loadedURL: String?
        var hasAdBlock = false
        var needsFiltering = false
        var onFiltered: (() -> Void)?
        var lastSearchTrigger = 0
        weak var webView: WKWebView?
        private var retryStage = 0

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            retryNext()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            retryNext()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let keywords = (try? AppDatabase.shared.contentFilterKeywords()) ?? []
            let settings = AppSettings.shared

            print("[MUFF-Filter] keywords=\(keywords) linkTables=\(settings.hideLinkTables) linkedImages=\(settings.hideLinkedImages) adBlock=\(settings.adBlockEnabled)")

            let js = Self.buildFilterScript(
                keywords: keywords,
                linkTables: settings.hideLinkTables,
                linkedImages: settings.hideLinkedImages,
                adBlock: settings.adBlockEnabled
            )

            webView.evaluateJavaScript(js) { [weak self] result, error in
                guard let self else { return }
                print("[MUFF-Filter] result=\(String(describing: result)) error=\(String(describing: error))")
                if let length = result as? Int, length < 10 {
                    self.retryNext()
                } else {
                    self.revealContent(in: webView)
                }
            }
        }

        private func revealContent(in webView: WKWebView) {
            if needsFiltering {
                webView.evaluateJavaScript("document.documentElement.style.opacity='1';", completionHandler: nil)
            }
            DispatchQueue.main.async { [weak self] in
                self?.onFiltered?()
            }
        }

        private func retryNext() {
            guard let webView else { return }
            retryStage += 1
            switch retryStage {
            case 1:
                if hasAdBlock, let loadedURL, let url = URL(string: loadedURL) {
                    webView.configuration.userContentController.removeAllContentRuleLists()
                    webView.load(URLRequest(url: url))
                } else {
                    retryNext()
                }
            case 2:
                if let loadedURL, loadedURL.hasPrefix("https://"),
                   let httpURL = URL(string: loadedURL.replacingOccurrences(of: "https://", with: "http://")) {
                    self.loadedURL = httpURL.absoluteString
                    webView.load(URLRequest(url: httpURL))
                }
            default:
                break
            }
        }

        // MARK: - Filter Script Builder

        private static func buildFilterScript(
            keywords: [String],
            linkTables: Bool,
            linkedImages: Bool,
            adBlock: Bool
        ) -> String {
            let needsEmbed = linkedImages || adBlock
            var js = "(function(){\ntry{\nif(!document.body)return 0;\n"

            // Shared variables
            js += "var H=window.location.hostname;\n"
            js += "var C='blockquote,dd,cite,figcaption';\n"
            js += "var bodyLen=(document.body.textContent||'').trim().length;\n"

            if needsEmbed {
                js += "var E=/youtube\\.com|youtu\\.be|youtube-nocookie\\.com|twitter\\.com|x\\.com|instagram\\.com|tiktok\\.com|nicovideo\\.jp|nico\\.ms|spotify\\.com|soundcloud\\.com|twitch\\.tv|dailymotion\\.com|vimeo\\.com|imgur\\.com|reddit\\.com|facebook\\.com|threads\\.net|bsky\\.app/;\n"
            }

            // Track hidden text for safety check
            if !keywords.isEmpty || linkTables {
                js += "var totH=0;\n"
            }

            // --- Phase 1: Content filters (keyword + link tables) ---

            if !keywords.isEmpty {
                let escaped = keywords.map {
                    $0.replacingOccurrences(of: "\\", with: "\\\\")
                      .replacingOccurrences(of: "\"", with: "\\\"")
                }
                let kwArray = escaped.map { "\"\($0)\"" }.joined(separator: ",")
                js += """
                var _kw=[\(kwArray)];
                function hideKW(){
                var BLK={DIV:1,SECTION:1,ASIDE:1,NAV:1,UL:1,OL:1,TABLE:1,DETAILS:1};
                var HDR={H1:1,H2:1,H3:1,H4:1,H5:1,H6:1};
                var th=[];
                function addSibs(s){
                var sib=s.nextElementSibling;
                while(sib){
                if(HDR[sib.tagName])break;
                if(BLK[sib.tagName]){
                var st=(sib.textContent||'').trim().length;
                if(st<bodyLen*0.3)th.push(sib);
                break;}
                th.push(sib);sib=sib.nextElementSibling;}}
                var w=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT,null,false);
                while(w.nextNode()){
                var txt=w.currentNode.textContent.trim();
                for(var i=0;i<_kw.length;i++){
                if(txt.indexOf(_kw[i])!==-1){
                var el=w.currentNode.parentElement;
                while(el&&el!==document.body){
                var tag=el.tagName;
                if(HDR[tag]){
                th.push(el);addSibs(el);break;}
                if(BLK[tag]){
                if((el.textContent||'').trim().length<bodyLen*0.3){
                th.push(el);
                }else{
                var node=w.currentNode.parentElement;
                if(node!==el){
                while(node&&node.parentElement!==el)node=node.parentElement;
                if(node&&node.parentElement===el){
                var nLen=(node.textContent||'').trim().length;
                if(nLen<200){th.push(node);addSibs(node);}}}}
                break;}
                el=el.parentElement;}
                break;}}}
                for(var i=0;i<th.length;i++){
                if(th[i].getAttribute('data-muff-hidden'))continue;
                totH+=(th[i].textContent||'').trim().length;
                th[i].setAttribute('data-muff-hidden','1');
                th[i].style.display='none';}}
                hideKW();\n
                """
            }

            if linkTables {
                js += """
                function isLC(ch){
                var tag=ch.tagName;
                if(tag==='BLOCKQUOTE'||ch.getElementsByTagName('blockquote').length>0)return false;
                var t=(ch.textContent||'').trim();
                if(!t.length||t.length>200)return false;
                if(tag==='A')return true;
                var lnks=ch.getElementsByTagName('a');
                if(lnks.length<1)return false;
                var lt=0;
                for(var j=0;j<lnks.length;j++)lt+=(lnks[j].textContent||'').trim().length;
                return lt/t.length>0.5;}
                function hideLB(){
                if(!document.body)return;
                var els=document.querySelectorAll('div,section,aside,ul,ol,table,details,nav,dl');
                for(var i=0;i<els.length;i++){
                var el=els[i];
                if(!el.offsetHeight||el.closest('[data-muff-hidden]'))continue;
                var ch=el.children;
                if(ch.length<2)continue;
                var eLen=(el.textContent||'').trim().length;
                var big=eLen>bodyLen*0.5;
                var lc=0,les=[];
                for(var c=0;c<ch.length;c++){if(isLC(ch[c])){lc++;les.push(ch[c]);}}
                if(lc>=3&&lc/ch.length>0.5&&!big){
                totH+=eLen;
                el.setAttribute('data-muff-hidden','1');
                el.style.display='none';
                }else if(lc>=3){
                for(var m=0;m<les.length;m++){
                totH+=(les[m].textContent||'').trim().length;
                les[m].setAttribute('data-muff-hidden','1');
                les[m].style.display='none';}}}}
                hideLB();\n
                """
            }

            // Safety check: undo if >90% of body text was hidden
            if !keywords.isEmpty || linkTables {
                js += """
                if(bodyLen>0&&totH>bodyLen*0.9){
                var hh=document.querySelectorAll('[data-muff-hidden]');
                for(var i=0;i<hh.length;i++){hh[i].style.display='';hh[i].removeAttribute('data-muff-hidden');}}\n
                """
            }

            // --- Phase 2: Image & ad filters ---

            if linkedImages {
                js += """
                function hideImgs(){
                var links=document.querySelectorAll('a');
                for(var i=0;i<links.length;i++){
                var a=links[i];
                var img=a.querySelector('img');
                if(a.style.display==='none'||!img||a.closest(C))continue;
                try{
                var u=new URL(a.href);
                if(u.hostname===H)continue;
                if(E.test(u.hostname))continue;
                if(/\\.(jpe?g|png|gif|webp|svg)$/.test(u.pathname.toLowerCase()))continue;
                try{if(new URL(img.src).hostname===H)continue;}catch(e){}
                a.style.display='none';
                }catch(e){}}}
                hideImgs();\n
                """
            }

            if adBlock {
                js += """
                var AD=/googlesyndication|doubleclick|adnxs|amazon-adsystem|criteo|outbrain|taboola|microad|i-mobile|nend\\.net|impact-ad|adstir|ad-stir|fluct|geniee|logly|shinobi|gmossp|amoad|ad-generation|zucks|popin|reemo|adsrvr|pubmatic|openx|bidswitch|rubiconproject|socdm|yieldone|adingo|aladsp|ad-track|blogroll\\.livedoor|speee-ad|uzou|compass-fit|ladsp|prdsrv/;
                var ASEL='ins.adsbygoogle,[id*="div-gpt-ad"],[data-ad-slot],[data-ad-unit],[class*="adsbygoogle"],[id*="google_ads"],[class*="ad-banner"],[class*="ad-container"],[class*="ad_container"],[class*="ad-area"],[class*="ad_area"],[class*="sponsor-area"],[class*="ad-box"],[class*="ad_box"],[id*="ad-wrapper"],[class*="ad-wrapper"],[id*="ads-"],[class*="blogroll"],[class*="ad_block"]';
                function hideAds(){
                var ifs=document.querySelectorAll('iframe');
                for(var i=0;i<ifs.length;i++){
                var src=ifs[i].src||'';
                if(AD.test(src)){ifs[i].style.display='none';continue;}
                try{if(src){var ih=new URL(src).hostname;if(ih!==H&&!E.test(ih))ifs[i].style.display='none';}}catch(e){}}
                try{var ae=document.querySelectorAll(ASEL);for(var i=0;i<ae.length;i++)ae[i].style.display='none';}catch(e){}
                var pts=document.elementsFromPoint(window.innerWidth/2,window.innerHeight-10);
                for(var i=0;i<pts.length;i++){
                var el=pts[i];
                if(el===document.body||el===document.documentElement)continue;
                var cs=getComputedStyle(el);
                if(cs.position!=='fixed'&&cs.position!=='sticky')continue;
                var ad=el.querySelectorAll('iframe').length>0;
                if(!ad){var lnks=el.querySelectorAll('a[href]');for(var j=0;j<lnks.length;j++){try{if(new URL(lnks[j].href).hostname!==H){ad=true;break;}}catch(e){}}}
                if(ad)el.style.display='none';}
                var oImgs=document.querySelectorAll('img[onclick]');
                for(var i=0;i<oImgs.length;i++){
                if(oImgs[i].closest(C))continue;
                var w=oImgs[i].offsetWidth||oImgs[i].naturalWidth||0;
                if(w>200)oImgs[i].style.display='none';}}
                hideAds();\n
                """
            }

            // --- Phase 3: Delayed re-runs ---

            var rerunCalls: [String] = []
            if !keywords.isEmpty { rerunCalls.append("hideKW();") }
            if linkTables { rerunCalls.append("hideLB();") }
            if linkedImages { rerunCalls.append("hideImgs();") }
            if adBlock { rerunCalls.append("hideAds();") }

            if !rerunCalls.isEmpty {
                let body = rerunCalls.joined()
                js += """
                function _rr(){\(body)}
                setTimeout(_rr,2000);
                var _t=null;
                var _o=new MutationObserver(function(){if(_t)clearTimeout(_t);_t=setTimeout(_rr,300);});
                _o.observe(document.body,{childList:true,subtree:true});
                setTimeout(function(){_o.disconnect();},8000);\n
                """
            }

            // Return content length for blank page check
            js += "return(document.body.innerText||'').trim().length;\n"
            js += "}catch(e){return 1;}\n})()"

            return js
        }
    }
}
