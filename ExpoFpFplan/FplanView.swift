import Foundation
import SwiftUI
import Combine
import WebKit
import UIKit
import ExpoFpCommon

/**
 Views to display the floor plan
 
 You can create a floor plan on the https://expofp.com
 */
@available(iOS 13.0, *)
public struct FplanView: UIViewRepresentable {
    
    private let url: String
    private let eventId: String
    private let noOverlay: Bool
    
    private let locationProvider: LocationProvider?
    private let useGlobalLocationProvider: Bool
    private let configuration: Configuration?
    
    @Binding private var selectedBooth: String?
    
    private let route: Route?
    
    private let currentPosition: BlueDotPoint?
    private let focusOnCurrentPosition: Bool
    
    private let selectBoothAction: ((_ boothName: String) -> Void)?
    private let fpReadyAction: (() -> Void)?
    private let buildDirectionAction: ((_ direction: Direction) -> Void)?
    private let messageReceivedAction: ((_ message: String) -> Void)?
    
    @State private var webViewController = FSWebViewController()
    
    /**
     This function initializes the view.
     Recommended for use in UIKit.
     
     **Parameters:**
     - url: Floor plan URL address in the format https://[expo_name].expofp.com
     - eventId = [expo_name]: Id of the expo
     - noOverlay: True - Hides the panel with information about exhibitors
     - locationProvider: Coordinate provider
     - useGlobalLocationProvider: True - use Global coordinate provider
     - configuration: Fplan configuration
     - selectBoothAction: Callback to be called after the booth has been select
     - fpReadyAction: Callback to be called after the floor plan has been ready
     - buildDirectionAction: Callback to be called after the route has been built
     - messageReceivedAction: Callback called when a custom message is received
     */
    public init(_ url: String,
                eventId: String? = nil,
                noOverlay: Bool = true,
                locationProvider: LocationProvider? = nil,
                useGlobalLocationProvider: Bool = false,
                configuration: Configuration? = nil,
                selectBoothAction: ((_ boothName: String) -> Void)? = nil,
                fpReadyAction:(() -> Void)? = nil,
                buildDirectionAction: ((_ direction: Direction) -> Void)? = nil,
                messageReceivedAction: ((_ message: String) -> Void)? = nil) {
        
        let eventAddress = Helper.getEventAddress(url)
        let eventUrl = "https://\(eventAddress)"
        
        self.url = eventUrl
        self.eventId = eventId ?? Helper.getEventId(eventUrl)
        self.noOverlay = noOverlay
        self.locationProvider = locationProvider
        self.useGlobalLocationProvider = useGlobalLocationProvider
        self.configuration = configuration
        
        self._selectedBooth = Binding.constant(nil)
        
        self.route = nil
        
        self.currentPosition = nil
        self.focusOnCurrentPosition = false
        
        self.selectBoothAction = nil
        self.fpReadyAction = fpReadyAction
        self.buildDirectionAction = buildDirectionAction
        self.messageReceivedAction = messageReceivedAction
    }
    
    
    /**
     This function initializes the view.
     Recommended for use in SwiftUI.
     
     **Parameters:**
     - url: Floor plan URL address in the format https://[expo_name].expofp.com
     - eventId = [expo_name]: Id of the expo
     - noOverlay: True - Hides the panel with information about exhibitors
     - locationProvider: Coordinate provider
     - useGlobalLocationProvider: True - use Global coordinate provider
     - configuration: Fplan configuration
     - selectedBooth: Booth selected on the floor plan
     - route: Information about the route to be built.
            After the route is built, the buildDirectionAction callback is called.
     - currentPosition: Current position on the floor plan
     - focusOnCurrentPosition: Focus on current position
     - fpReadyAction: Callback to be called after the floor plan has been ready
     - buildDirectionAction: Callback to be called after the route has been built
     - messageReceivedAction: Callback called when a custom message is received
     */
    public init(_ url: String,
                eventId: String? = nil,
                noOverlay: Bool = true,
                locationProvider: LocationProvider? = nil,
                useGlobalLocationProvider: Bool = false,
                configuration: Configuration? = nil,
                selectedBooth: Binding<String?>? = nil,
                route: Route? = nil,
                currentPosition: BlueDotPoint? = nil,
                focusOnCurrentPosition: Bool = false,
                fpReadyAction:(() -> Void)? = nil,
                buildDirectionAction: ((_ direction: Direction) -> Void)? = nil,
                messageReceivedAction: ((_ message: String) -> Void)? = nil){
        
        let eventAddress = Helper.getEventAddress(url)
        let eventUrl = "https://\(eventAddress)"
        
        self.url = eventUrl
        self.eventId = eventId ?? Helper.getEventId(eventUrl)
        self.noOverlay = noOverlay
        self.locationProvider = locationProvider
        self.useGlobalLocationProvider = useGlobalLocationProvider
        self.configuration = configuration
        
        self._selectedBooth = selectedBooth ?? Binding.constant(nil)
        
        self.route = route
        
        self.currentPosition = currentPosition
        self.focusOnCurrentPosition = focusOnCurrentPosition
        
        self.selectBoothAction = nil
        self.fpReadyAction = fpReadyAction
        self.buildDirectionAction = buildDirectionAction
        self.messageReceivedAction = messageReceivedAction
    }
    
    public func makeUIView(context: Context) -> FSWebView {
        let preferences = WKPreferences()
        preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        preferences.setValue(true, forKey: "offlineApplicationCacheIsEnabled")
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.setURLSchemeHandler(webViewController, forURLScheme: Constants.scheme)
        
        let webView = FSWebView(frame: CGRect.zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        webView.navigationDelegate = webViewController
        webViewController.wkWebView = webView
        
        webView.addObserver(webViewController, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        
        webView.configuration.userContentController.add(FpHandler(webView, fpReady), name: "onFpConfiguredHandler")
        webView.configuration.userContentController.add(BoothHandler(webView, selectBooth), name: "onBoothClickHandler")
        webView.configuration.userContentController.add(DirectionHandler(webView, buildDirection), name: "onDirectionHandler")
        webView.configuration.userContentController.add(MessageHandler(webView, messageReceived), name: "messageHandler")
        
        return webView
    }
    
    public func updateUIView(_ webView: FSWebView, context: Context) {
        let eventAddress = Helper.getEventAddress(self.url)
        let eventUrl = "https://\(eventAddress)"
        
        if(webViewController.expoUrl != eventUrl){
            initWebView(webView)
        }
        else{
            updateWebView(webView)
        }
    }
    
    /**
     This function selects a booth on the floor plan.
     
     **Parameters:**
     - boothName: Booth name
     */
    public func selectBooth(_ boothName: String?){
        webViewController.selectBooth(boothName)
    }
    
    /**
     This function starts the process of building a route from one booth to another.
     After the route is built, the buildDirectionAction callback is called.
     
     **Parameters:**
     - route: Route info
     */
    public func buildRoute(_ route: Route?){
        webViewController.buildRoute(route)
    }
    
    /**
     This function sets a blue-dot point.
     
     **Parameters:**
     - position: Coordinates.
     - focus: True - focus the floor plan display on the passed coordinates.
     */
    public func setCurrentPosition(_ position: BlueDotPoint?, _ focus: Bool = false){
        webViewController.setCurrentPosition(position, focus)
    }
    
    /**
     This function clears the floor plan
     */
    public func clear() {
        selectBooth(nil)
        buildRoute(nil)
        setCurrentPosition(nil)
    }
    
    private func updateWebView(_ webView: FSWebView) {
        if(webViewController.selectedBooth != self.selectedBooth){
            if(self.selectedBooth != nil && self.selectedBooth != "" && self.route == nil){
                selectBooth(self.selectedBooth)
            }
            else if(self.route == nil){
                selectBooth(nil)
            }
        }
        
        if(webViewController.route != self.route){
            if(self.route != nil){
                buildRoute(self.route)
            }
            else if(self.selectedBooth == nil){
                buildRoute(nil)
            }
        }
        
        if(webViewController.currentPosition != self.currentPosition){
            if(self.currentPosition != nil){
                setCurrentPosition(self.currentPosition)
            }
            else{
                setCurrentPosition(nil)
            }
        }
    }
    
    private func initWebView(_ webView: FSWebView) {
        let fileManager = FileManager.default
        let netReachability = NetworkReachability()
        let online = netReachability.checkConnection()
        
        let eventAddress = Helper.getEventAddress(self.url)
        let eventUrl = "https://\(eventAddress)"
        
        let fplanDirectory = Helper.getCacheDirectory().appendingPathComponent("fplan/")
        let eventDirectory = fplanDirectory.appendingPathComponent("\(eventAddress)/")
        
        let indexPath = eventDirectory.appendingPathComponent("index.html")
        let fplanConfigPath = eventDirectory.appendingPathComponent(Constants.fplanConfigPath)
        let fplanConfigUrl = URL(string:"\(eventUrl)/\(Constants.fplanConfigPath)")
        
        let baseUrl = "\(Constants.scheme)://\(eventDirectory.path)"
        let indexUrlString = selectedBooth != nil && selectedBooth != "" ? baseUrl + "/index.html" + "?\(selectedBooth!)" : baseUrl + "/index.html"
        let indexUrl = URL(string: indexUrlString)
        
        if(online){
            loadConfiguration(fplanConfigUrl: fplanConfigUrl!, eventUrl: eventUrl){ config in
                
                webViewController.setExpo(eventUrl, eventDirectory.absoluteString, config)
                
                if fileManager.fileExists(atPath: fplanDirectory.path){
                    try? fileManager.removeItem(at: fplanDirectory)
                }
                
                try? saveConfiguration(config, fplanConfigPath: fplanConfigPath)
                
                loadHtmlFile(configuration: config){ html in
                    try? Helper.createHtmlFile(filePath: indexPath, html: html, noOverlay: self.noOverlay, baseUrl: baseUrl, eventId: self.eventId)
                    
                    DispatchQueue.main.async {
                        let requestUrl = URLRequest(url: indexUrl!, cachePolicy: .reloadRevalidatingCacheData)
                        webView.load(requestUrl)
                    }
                    
                    Helper.downloadFiles(config.files, eventDirectory){
                        initFloorplan(webView)
                    }
                }
            }
        }
        else {
            guard let config = try? loadConfiguration(fplanConfigPath: fplanConfigPath) else {
                return
            }
            
            webViewController.setExpo(eventUrl, eventDirectory.absoluteString, config){
                initFloorplan(webView)
            }
            
            if !fileManager.fileExists(atPath: indexPath.path) {
                print("[Fplan] Html file loaded from assets")
                let html = Helper.getDefaultHtmlFile()
                try? Helper.createHtmlFile(filePath: indexPath, html: html, noOverlay: self.noOverlay, baseUrl: baseUrl, eventId: self.eventId)
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
        updateWebView(webView)
        self.fpReadyAction?()
        
        let enablePositioning = webViewController.configuration == nil
            || webViewController.configuration!.enablePositioningAfter == nil
            || webViewController.configuration!.enablePositioningAfter! < Date()
        
        if(enablePositioning && self.useGlobalLocationProvider){
            webViewController.setGlobalLocationProvider(provider: GlobalLocationProvider.getLocationProvider())
        }
        else {
            webViewController.setGlobalLocationProvider(provider: nil)
        }
        
        if(enablePositioning) {
            webViewController.setLocationProvider(provider: self.locationProvider)
        }
        else {
            webViewController.setLocationProvider(provider: nil)
        }
    }
    
    private func selectBooth(_ webView: FSWebView, _ boothName: String){
        self.selectedBooth = boothName
        self.selectBoothAction?(boothName)
    }
    
    private func buildDirection(_ webView: FSWebView, _ direction: Direction){
        self.buildDirectionAction?(direction)
    }
    
    private func messageReceived(_ webView: FSWebView, _ message: String){
        if(self.messageReceivedAction != nil){
            self.messageReceivedAction?(message)
        }
    }
    
    private func loadHtmlFile(configuration: Configuration, callback: @escaping ((_ html: String) -> Void)){
        if(configuration.iosHtmlUrl != nil && configuration.iosHtmlUrl != ""){
            let session = URLSession.shared
            let task = session.dataTask(with: URL(string: configuration.iosHtmlUrl!)!, completionHandler: { data, response, error in
                if let html = data {
                    print("[Fplan] Html file loaded from \(configuration.iosHtmlUrl!)")
                    callback(String(decoding: html, as: UTF8.self))
                }
                else {
                    print("[Fplan] Html file loaded from assets")
                    callback(Helper.getDefaultHtmlFile())
                }
            })
            task.resume()
        }
        else {
            print("[Fplan] Html file loaded from assets")
            callback(Helper.getDefaultHtmlFile())
        }
    }
    
    private func saveConfiguration(_ configuration: Configuration, fplanConfigPath: URL) throws {
        let jsonEncoder = JSONEncoder()
        
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        jsonEncoder.dateEncodingStrategy = .custom({ date, encoder in
                var singleValueEnc = encoder.singleValueContainer()
                try singleValueEnc.encode(formatter.string(from: date))
        })
        
        let jsonData = try jsonEncoder.encode(configuration)
        let configJson = String(data: jsonData, encoding: String.Encoding.utf8)
        
        try configJson!.write(to: fplanConfigPath, atomically: true, encoding: String.Encoding.utf8)
    }
    
    private func parseConfigurationJson(_ json: Data) throws -> Configuration {
        let decoder = JSONDecoder()

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            
            throw DateError.invalidDate
        })
        
        let config = try decoder.decode(Configuration.self, from: json)
        return config
    }
    
    private func loadConfiguration(fplanConfigPath: URL) throws -> Configuration {
        let json = try String.init(contentsOf: fplanConfigPath)
        return try parseConfigurationJson(json.data(using: .utf8)!)
    }
    
    private func loadConfiguration(fplanConfigUrl: URL, eventUrl: String, callback: @escaping ((_ configuration: Configuration) -> Void)) {
        if(self.configuration != nil){
            callback(self.configuration!)
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: fplanConfigUrl, completionHandler: { data, response, error in
            
            if let json = data {
                guard let config = try? parseConfigurationJson(json) else {
                    print("[Fplan] Config file loaded from assets")
                    let config = Helper.getDefaultConfiguration(baseUrl: eventUrl)
                    callback(config)
                    return
                }
                
                print("[Fplan] Config file loaded from \(fplanConfigUrl.absoluteString)")
                callback(config)
            }
            else {
                print("[Fplan] Config file loaded from assets")
                let config = Helper.getDefaultConfiguration(baseUrl: eventUrl)
                callback(config)
            }
            
            
        })
        task.resume()
    }
}

@available(iOS 13.0.0, *)
public struct FplanView_Previews: PreviewProvider {
    
    public init(){
    }
    
    public static var previews: some View {
        FplanView("https://demo.expofp.com")
    }
}
