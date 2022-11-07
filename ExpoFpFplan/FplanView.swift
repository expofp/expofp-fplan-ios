import Foundation
import SwiftUI
import Combine
import WebKit
import UIKit
import ExpoFpCommon


public extension FplanView {
    
    func onFpReady(_ callback: @escaping () -> Void) -> FplanView {
        self.webViewController.fpReadyAction = callback
        return self
    }
    
    func onBoothClick(_ callback: @escaping (_ boothName: String) -> Void) -> FplanView {
        self.webViewController.selectBoothAction = callback
        return self
    }
    
    func onBuildDirection(_ callback: @escaping (_ direction: Direction) -> Void) -> FplanView {
        self.webViewController.buildDirectionAction = callback
        return self
    }
    
    func onMessageReceived(_ callback: @escaping (_ message: String) -> Void) -> FplanView {
        self.webViewController.messageReceivedAction = callback
        return self
    }
}

/**
 Views to display the floor plan
 
 You can create a floor plan on the https://expofp.com
 */
//@available(iOS 13.0, *)
public struct FplanView: UIViewRepresentable {
    
    @State private var webViewController = FSWebViewController()
    
    public init() {
    }
    
    public func makeUIView(context: Context) -> FSWebView {
        let preferences = WKPreferences()
        preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        preferences.setValue(true, forKey: "offlineApplicationCacheIsEnabled")
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.setURLSchemeHandler(self.webViewController, forURLScheme: Constants.scheme)
        
        let webView = FSWebView(frame: CGRect.zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = self.webViewController
        //webView.uiDelegate = self.webViewController
        self.webViewController.wkWebView = webView
        
        webView.addObserver(self.webViewController, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        
        webView.configuration.userContentController.add(FpHandler(webView, fpReady), name: "onFpConfiguredHandler")
        webView.configuration.userContentController.add(BoothHandler(webView, selectBooth), name: "onBoothClickHandler")
        webView.configuration.userContentController.add(DirectionHandler(webView, buildDirection), name: "onDirectionHandler")
        webView.configuration.userContentController.add(MessageHandler(webView, messageReceived), name: "messageHandler")
        webView.configuration.userContentController.add(DetailsHandler(onDetails), name: "detailsHandler")
               
        return webView
    }
    
    public func updateUIView(_ webView: FSWebView, context: Context) {
    }
    
    public func destoy() {
        if var gLocProvider = self.webViewController.globalLocationProvider {
            gLocProvider.delegate = nil
        }
        
        if var locProvider = self.webViewController.locationProvider {
            locProvider.delegate = nil
            locProvider.stop()
        }
        
        self.webViewController.fpReadyAction = nil
        self.webViewController.selectBoothAction = nil
        self.webViewController.buildDirectionAction = nil
        self.webViewController.messageReceivedAction = nil
        self.webViewController.configuration = nil
        
        self.webViewController.globalLocationProvider = nil
        self.webViewController.locationProvider = nil
    }
    
    public func load(_ url: String, noOverlay: Bool = false) {
        load(url, noOverlay: noOverlay, locationProvider: nil)
    }
    
    public func load(_ url: String, noOverlay: Bool = false, locationProvider: LocationProvider? = nil) {
        load(url, noOverlay: noOverlay, locationProvider: locationProvider, configuration: nil)
    }
    
    public func load(_ url: String, noOverlay: Bool = false, locationProvider: LocationProvider? = nil, configuration: Configuration? = nil) {
        if let webView = self.webViewController.wkWebView {
            load(webView, url, noOverlay, locationProvider: locationProvider, globalLocationProvider: nil, configuration: configuration)
        }
    }
    
    public func load(_ url: String, noOverlay: Bool = false, useGlobalLocationProvider: Bool = false) {
        load(url, noOverlay: noOverlay, useGlobalLocationProvider: useGlobalLocationProvider, configuration: nil)
    }
    
    public func load(_ url: String, noOverlay: Bool = false, useGlobalLocationProvider: Bool = false, configuration: Configuration? = nil) {
        if let webView = self.webViewController.wkWebView {
            let gLocProvider = useGlobalLocationProvider ? GlobalLocationProvider.getLocationProvider() : nil
            load(webView, url, noOverlay, locationProvider: nil, globalLocationProvider: gLocProvider, configuration: configuration)
        }
    }
    
    /**
     This function selects a exhibitor on the floor plan.
     
     **Parameters:**
     - exhibitorName: Exhibitor name
     */
    public func selectExhibitor(_ exhibitorName: String?){
        self.webViewController.selectExhibitor(exhibitorName)
    }
    
    /**
     This function selects a booth on the floor plan.
     
     **Parameters:**
     - boothName: Booth name
     */
    public func selectBooth(_ boothName: String?){
        self.webViewController.selectBooth(boothName)
    }
    
    /**
     This function starts the process of building a route from one booth to another.
     After the route is built, the buildDirectionAction callback is called.
     
     **Parameters:**
     - route: Route info
     */
    public func buildRoute(_ route: Route?){
        self.webViewController.buildRoute(route)
    }
    
    /**
     This function sets a blue-dot point.
     
     **Parameters:**
     - position: Coordinates.
     - focus: True - focus the floor plan display on the passed coordinates.
     */
    public func setCurrentPosition(_ position: BlueDotPoint?, _ focus: Bool = false){
        self.webViewController.setCurrentPosition(position, focus)
    }
    
    /**
     This function clears the floor plan
     */
    public func clear() {
        selectBooth(nil)
        buildRoute(nil)
        setCurrentPosition(nil)
    }
    
    private func load(_ webView: FSWebView, _ url: String, _ noOverlay: Bool,
                      locationProvider: LocationProvider? = nil,
                      globalLocationProvider: LocationProvider? = nil,
                      configuration: Configuration? = nil) {
        
        webViewController.locationProvider = locationProvider
        webViewController.globalLocationProvider = globalLocationProvider
        
        let fileManager = FileManager.default
        let netReachability = NetworkReachability()
        let online = netReachability.checkConnection()
        
        let eventId = Helper.getEventId(url)
        let eventAddress = Helper.getEventAddress(url)
        let eventUrl = "https://\(eventAddress)"
        
        let params = Helper.getParams(url)
        
        let fplanDirectory = Helper.getCacheDirectory().appendingPathComponent("fplan/")
        let eventDirectory = fplanDirectory.appendingPathComponent("\(eventAddress)/")
        
        let indexPath = eventDirectory.appendingPathComponent("index.html")
        let fplanConfigPath = eventDirectory.appendingPathComponent(Constants.fplanConfigPath)
        let fplanConfigUrl = URL(string:"\(eventUrl)/\(Constants.fplanConfigPath)")
        
        let baseUrl = "\(Constants.scheme)://\(eventDirectory.path)"
        //let indexUrlString = selectedBooth != nil && selectedBooth != "" ? baseUrl + "/index.html" + "?\(selectedBooth!)" : baseUrl + "/index.html"
        let indexUrlString = baseUrl + "/index.html" + params
        let indexUrl = URL(string: indexUrlString)
        
        //webViewController.setExpo(eventUrl, eventDirectory.absoluteString)
        self.webViewController.expoUrl = eventUrl
        self.webViewController.expoCacheDirectory = eventDirectory.absoluteString
        
        if(online){
            Helper.loadConfiguration(configuration, fplanConfigUrl: fplanConfigUrl!, eventUrl: eventUrl){ config in
                
                self.webViewController.configuration = config
                
                if fileManager.fileExists(atPath: fplanDirectory.path){
                    try? fileManager.removeItem(at: fplanDirectory)
                }
                
                try? Helper.saveConfiguration(config, fplanConfigPath: fplanConfigPath)
                
                self.webViewController.loadedAction = {
                    Helper.downloadFiles(config.files, eventDirectory){
                        initFloorplan(webView)
                    }
                }
                
                Helper.loadHtmlFile(configuration: config){ html in
                    try? Helper.createHtmlFile(filePath: indexPath, html: html, noOverlay: noOverlay, baseUrl: baseUrl, eventId: eventId)
                    
                    DispatchQueue.main.async {
                        let requestUrl = URLRequest(url: indexUrl!, cachePolicy: .reloadRevalidatingCacheData)
                        webView.load(requestUrl)
                    }
                }
            }
        }
        else {
            if(configuration != nil){
                self.webViewController.configuration = configuration
            }
            else {
                guard let config = try? Helper.loadConfiguration(fplanConfigPath: fplanConfigPath) else {
                    print("[Fplan] Offline mode. Failed to read config file from cache.")
                    return
                }
                self.webViewController.configuration = config
            }
            
            self.webViewController.loadedAction = {
                initFloorplan(webView)
            }
            
            if !fileManager.fileExists(atPath: indexPath.path) {
                print("[Fplan] Html file loaded from assets")
                let html = Helper.getDefaultHtmlFile()
                try? Helper.createHtmlFile(filePath: indexPath, html: html, noOverlay: noOverlay, baseUrl: baseUrl, eventId: eventId)
            }
            
            DispatchQueue.main.async {
                let requestUrl = URLRequest(url: indexUrl!, cachePolicy: .returnCacheDataDontLoad)
                webView.load(requestUrl)
            }
        }
    }
    
    private func initFloorplan(_ webView: FSWebView) {
        DispatchQueue.main.async {
            webView.evaluateJavaScript("window.init()")
        }
    }

    private func fpReady(_ webView: FSWebView){
        self.webViewController.fpReadyAction?();
        
        let enablePositioning = self.webViewController.configuration == nil
        || ((self.webViewController.configuration!.enablePositioningAfter == nil
             || self.webViewController.configuration!.enablePositioningAfter! < Date())
            && (self.webViewController.configuration!.disablePositioningAfter == nil
                || self.webViewController.configuration!.disablePositioningAfter! > Date()))
        
        if(enablePositioning){
            if var gLocProvider = self.webViewController.globalLocationProvider {
                gLocProvider.delegate = self.webViewController
            }
            else if var locProvider = self.webViewController.locationProvider {
                locProvider.delegate = self.webViewController
                locProvider.start()
            }
        }
    }
    
    private func selectBooth(_ webView: FSWebView, _ boothName: String){
        self.webViewController.selectBoothAction?(boothName)
    }
    
    private func buildDirection(_ webView: FSWebView, _ direction: Direction){
        self.webViewController.buildDirectionAction?(direction)
    }
    
    private func messageReceived(_ webView: FSWebView, _ message: String){
        self.webViewController.messageReceivedAction?(message)
    }
    
    private func onDetails(_ details: Details?){
    }
}
