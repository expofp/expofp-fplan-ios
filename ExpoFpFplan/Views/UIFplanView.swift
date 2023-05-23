import UIKit
import WebKit
import ExpoFpCommon

open class UIFplanView : UIView {
    internal var webView: FSWebView!
    internal var config: Configuration?
    
    internal var locationProvider: LocationProvider?
    internal var globalLocationProvider: LocationProvider?
    
    internal var fpReadyCallback: (() -> Void)?
    internal var selectBoothCallback: ((_ id: String, _ name: String) -> Void)?
    internal var buildDirectionCallback: ((_ direction: Direction) -> Void)?
    internal var messageReceivedCallback: ((_ message: String) -> Void)?
    internal var detailsClickCallback: ((_ details: Details) -> Void)?
    internal var exhibitorCustomButtonClickCallback: ((_ externalId: String, _ buttonNumber: Int, _ buttonUrl: String) -> Void)?
    
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
                DispatchQueue.main.async() {

                    let jsOnFpConfigured = "window.webkit?.messageHandlers?.fpConfiguredHandler?.postMessage(\"FLOOR PLAN CONFIGURED\")"
                    let jsOnBoothClick = "window.___fp.onBoothClick = e => window.webkit?.messageHandlers?.boothClickHandler?.postMessage(JSON.stringify( {target: {id: e?.target?.id?.toString(), name: e?.target?.name }} ))"
                    let jsOnDirection = "window.___fp.onDirection = e => window.webkit?.messageHandlers?.directionHandler?.postMessage(JSON.stringify(e))"
                    let jsOnDetails = "window.___fp.onDetails = e => window.webkit?.messageHandlers?.detailsHandler?.postMessage(JSON.stringify(e))"
                    let jsOnExhibitorCustomButtonClick = "window.___fp.onExhibitorCustomButtonClick = e => window.webkit?.messageHandlers?.exhibitorCustomButtonClickHandler?.postMessage(JSON.stringify(e))"
                    
                    
                    let js = "___fp._ready.then(\(jsOnFpConfigured),\(jsOnBoothClick),\(jsOnDirection),\(jsOnDetails),\(jsOnExhibitorCustomButtonClick));"
                    self.webView.evaluateJavaScript(js)
                    
                    //self.webView.evaluateJavaScript("window.___fp && (window.___fp.onFpConfigured = () => window.webkit?.messageHandlers?.fpConfiguredHandler?.postMessage(\"FLOOR PLAN CONFIGURED\"));")
                    
                    /*self.webView.evaluateJavaScript("window.___fp && (window.___fp.onBoothClick = e => window.webkit?.messageHandlers?.boothClickHandler?.postMessage(JSON.stringify( {target: {id: e?.target?.id?.toString(), name: e?.target?.name }} )));")
                    
                    self.webView.evaluateJavaScript("window.___fp && (window.___fp.onDirection = e => window.webkit?.messageHandlers?.directionHandler?.postMessage(JSON.stringify(e)));")
                    
                    self.webView.evaluateJavaScript("window.___fp && (window.___fp.onDetails = e => window.webkit?.messageHandlers?.detailsHandler?.postMessage(JSON.stringify(e)));")
                    
                    self.webView.evaluateJavaScript("window.___fp && (window.___fp.onExhibitorCustomButtonClick = e => window.webkit?.messageHandlers?.exhibitorCustomButtonClickHandler?.postMessage(JSON.stringify(e)));")*/
                }
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
        
        webView.configuration.userContentController.add(FpHandler(fpReady), name: "fpConfiguredHandler")
        webView.configuration.userContentController.add(BoothHandler(selectBooth), name: "boothClickHandler")
        webView.configuration.userContentController.add(DirectionHandler(buildDirection), name: "directionHandler")
        webView.configuration.userContentController.add(DetailsHandler(onDetails), name: "detailsHandler")
        webView.configuration.userContentController.add(ExhibitorCustomButtonHandler(onExhibitorCustomButtonClick), name: "exhibitorCustomButtonClickHandler")
        
        webView.configuration.userContentController.add(MessageHandler(messageReceived), name: "messageHandler")
        
        addSubview(webView)
        self.webView = webView
    }
    
    private func fpReady(){
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
    
    private func selectBooth(_ event: FloorPlanBoothClickEvent){
        self.selectBoothCallback?(event.target.id, event.target.name)
    }
    
    private func buildDirection(_ direction: Direction){
        self.buildDirectionCallback?(direction)
    }
    
    private func messageReceived(_ message: String){
        self.messageReceivedCallback?(message)
    }
    
    private func onDetails(_ details: Details?){
        if let d = details {
            self.detailsClickCallback?(d)
        }
    }
    
    private func onExhibitorCustomButtonClick(_ event: FloorPlanCustomButtonEvent) {
        self.exhibitorCustomButtonClickCallback?(event.externalId, event.buttonNumber, event.buttonUrl)
    }
}
