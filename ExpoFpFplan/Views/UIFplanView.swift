import UIKit
import WebKit
import ExpoFpCommon

open class UIFplanView : UIView {
    internal var webView: FSWebView!
    internal var config: Configuration?
    
    internal var locationProvider: LocationProvider?
    internal var globalLocationProvider: LocationProvider?
    
    internal var selectBoothCallback: ((_ boothName: String) -> Void)?
    internal var fpReadyCallback: (() -> Void)?
    internal var buildDirectionCallback: ((_ direction: Direction) -> Void)?
    internal var messageReceivedCallback: ((_ message: String) -> Void)?
    
    internal var isFplanReady = false
    internal var isFplanDestroyed = false
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createWebView()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        createWebView()
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            if(webView.estimatedProgress == 1.0 ){
                self.webView.evaluateJavaScript("window.___fp && (window.___fp.onFpConfigured = () => window.webkit?.messageHandlers?.onFpConfiguredHandler?.postMessage(\"FLOOR PLAN CONFIGURED\"));")
                self.webView.evaluateJavaScript("window.___fp && (window.___fp.onBoothClick = e => window.webkit?.messageHandlers?.onBoothClickHandler?.postMessage(e?.target?.name));")
                self.webView.evaluateJavaScript("window.___fp && (window.___fp.onDirection = e => window.webkit?.messageHandlers?.onDirectionHandler?.postMessage(JSON.stringify(e)));")
            }
        }
    }
    
    private func createWebView() {
        let preferences = WKPreferences()
        preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        preferences.setValue(true, forKey: "offlineApplicationCacheIsEnabled")
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        let webView = FSWebView(frame: CGRect.zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        webView.frame = bounds
        webView.autoresizingMask = [
            UIView.AutoresizingMask.flexibleWidth,
            UIView.AutoresizingMask.flexibleHeight
        ]
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        
        webView.configuration.userContentController.add(FpHandler(webView, fpReady), name: "onFpConfiguredHandler")
        webView.configuration.userContentController.add(BoothHandler(webView, selectBooth), name: "onBoothClickHandler")
        webView.configuration.userContentController.add(DirectionHandler(webView, buildDirection), name: "onDirectionHandler")
        webView.configuration.userContentController.add(MessageHandler(webView, messageReceived), name: "messageHandler")
        webView.configuration.userContentController.add(DetailsHandler(onDetails), name: "detailsHandler")
        
        addSubview(webView)
        self.webView = webView
    }
    
    private func fpReady(_ webView: FSWebView){
        isFplanReady = true
        isFplanDestroyed = false
        
        self.fpReadyCallback?();
        
        let enablePositioning = self.config == nil
        || ((self.config!.enablePositioningAfter == nil
             || self.config!.enablePositioningAfter! < Date())
            && (self.config!.disablePositioningAfter == nil
                || self.config!.disablePositioningAfter! > Date()))
        
        if(enablePositioning){
            if var gLocProvider = self.globalLocationProvider {
                gLocProvider.delegate = self
            }
            else if var locProvider = self.locationProvider {
                locProvider.delegate = self
                locProvider.start()
            }
        }
    }
    
    private func selectBooth(_ webView: FSWebView, _ boothName: String){
        self.selectBoothCallback?(boothName)
    }
    
    private func buildDirection(_ webView: FSWebView, _ direction: Direction){
        self.buildDirectionCallback?(direction)
    }
    
    private func messageReceived(_ webView: FSWebView, _ message: String){
        self.messageReceivedCallback?(message)
    }
    
    private func onDetails(_ details: Details?){
    }
}
