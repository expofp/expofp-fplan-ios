import Foundation
import WebKit
import ExpoFpCommon
import ZIPFoundation

public extension UIFplanView {
    /**
     Set a callback that is called after the plan is initialized.
     
     **Parameters:**
     - callback: Callback
     */
    func setOnFpReadyCallback(_ callback: @escaping () -> Void){
        self.fpReadyCallback = callback
    }
    
    /**
     Set a callback that is called after selecting a booth on the plan.
     
     **Parameters:**
     - callback: Callback
     */
    func setOnBoothClickCallback(_ callback: @escaping (_ id: String?, _ name: String?) -> Void){
        self.selectBoothCallback = callback
    }
    
    /**
     Set a callback that is called after the route is built.
     
     **Parameters:**
     - callback: Callback
     */
    func setOnBuildDirectionCallback(_ callback: @escaping (_ direction: Direction?) -> Void){
        self.buildDirectionCallback = callback
    }
    
    /**
     Set a callback that is called after receiving a message from the plan.
     
     **Parameters:**
     - callback: Callback
     */
    func setOnMessageReceivedCallback(_ callback: @escaping (_ message: String?) -> Void){
        self.messageReceivedCallback = callback
    }
    
    /**
     Set a callback that is called after details is open.
     
     **Parameters:**
     - callback: Callback
     */
    func setOnDetailsClickCallback(_ callback: @escaping (_ details: Details?) -> Void){
        self.detailsClickCallback = callback
    }
    
    /**
     Set a callback that is called after custom button is click.
     
     **Parameters:**
     - callback: Callback
     */
    func setOnExhibitorCustomButtonClickCallback(_ callback: @escaping (_ externalId: String, _ buttonNumber: Int, _ buttonUrl: String) -> Void){
        self.exhibitorCustomButtonClickCallback = callback
    }
    
    
    /**
     Starts the plan loading process.
     
     **Parameters:**
     - url: Plan URL
     */
    func load(_ url: String){
        load(url, locationProvider: nil)
    }
    
    /**
     Starts the plan loading process.
     
     **Parameters:**
     - url: Plan URL.
     - locationProvider: Сoordinate provider.
     */
    func load(_ url: String, locationProvider: LocationProvider? = nil) {
        load(url, locationProvider: locationProvider, configuration: nil)
    }
    
    /**
     Start the plan loading process.
     
     **Parameters:**
     - url: Plan URL.
     - locationProvider: Сoordinate provider.
     - configuration: Plan config.
     */
    func load(_ url: String, locationProvider: LocationProvider? = nil, configuration: Configuration? = nil) {
        load(url, locationProvider: locationProvider, globalLocationProvider: nil, configuration: configuration)
    }
    
    /**
     Start the plan loading process.
     
     **Parameters:**
     - url: Plan URL.
     - useGlobalLocationProvider: Flag indicating whether to use the global coordinate provider.
     */
    func load(_ url: String, useGlobalLocationProvider: Bool = false) {
        load(url, useGlobalLocationProvider: useGlobalLocationProvider, configuration: nil)
    }
    
    /**
     Start the plan loading process.
     
     **Parameters:**
     - url: Plan URL.
     - useGlobalLocationProvider: Flag indicating whether to use the global coordinate provider.
     - configuration: Plan config.
     */
    func load(_ url: String, useGlobalLocationProvider: Bool = false, configuration: Configuration? = nil) {
        let gLocProvider = useGlobalLocationProvider ? GlobalLocationProvider.getLocationProvider() : nil
        load(url, locationProvider: nil, globalLocationProvider: gLocProvider, configuration: configuration)
    }
    
    func openZip(_ zipFilePath: String, params: String? = nil) {
        openZip(zipFilePath, params: params, locationProvider: nil)
    }
    
    func openZip(_ zipFilePath: String, params: String? = nil, locationProvider: LocationProvider? = nil) {
        openZip(zipFilePath, params: params, locationProvider: locationProvider, configuration: nil)
    }
    
    func openZip(_ zipFilePath: String, params: String? = nil, locationProvider: LocationProvider? = nil, configuration: Configuration? = nil) {
        openZip(zipFilePath, params: params, locationProvider: locationProvider, globalLocationProvider: nil, configuration: configuration)
    }
    
    func openZip(_ zipFilePath: String, params: String? = nil, useGlobalLocationProvider: Bool = false) {
        openZip(zipFilePath, params: params, useGlobalLocationProvider: useGlobalLocationProvider, configuration: nil)
    }
    
    func openZip(_ zipFilePath: String, params: String? = nil, useGlobalLocationProvider: Bool = false, configuration: Configuration? = nil) {
        let gLocProvider = useGlobalLocationProvider ? GlobalLocationProvider.getLocationProvider() : nil
        openZip(zipFilePath, params: params, locationProvider: nil, globalLocationProvider: gLocProvider, configuration: configuration)
    }
    
    func openZip(_ zipFilePath: String,
                 params: String? = nil,
                 locationProvider: LocationProvider? = nil,
                 globalLocationProvider: LocationProvider? = nil,
                 configuration: Configuration? = nil) {
        
        if(locationProvider != nil){
            self.locationProvider = locationProvider
        }
        
        if(globalLocationProvider != nil){
            self.globalLocationProvider = globalLocationProvider
        }
        
        if(configuration != nil){
            self.config = configuration
        }
        
        let zipFileURL = URL(fileURLWithPath: zipFilePath)
        let fplanDirectoryUrl = Helper.getCacheDirectory().appendingPathComponent("fplan/")
        let archivesDirectoryUrl = fplanDirectoryUrl.appendingPathComponent("archives/")
        let archivesDirectoryPath = archivesDirectoryUrl.path
        
        let fileManager = FileManager.default
        do {
            if(fileManager.fileExists(atPath: archivesDirectoryPath)){
                try fileManager.removeItem(at: archivesDirectoryUrl)
            }
            
            try fileManager.createDirectory(at: archivesDirectoryUrl, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: zipFileURL, to: archivesDirectoryUrl, progress: nil)
            
            if(fileManager.fileExists(atPath: archivesDirectoryPath)){
                if let items = try? fileManager.contentsOfDirectory(atPath: archivesDirectoryPath) {
                    let indexUrl: URL
                    if(params != nil){
                        let fParams = params!.hasPrefix("?") ? params! : "?\(params!)"
                        let indexUrlBase = archivesDirectoryUrl.appendingPathComponent("\(items[items.startIndex])/index.html")
                        indexUrl = URL(string: fParams, relativeTo: indexUrlBase)!
                    }
                    else {
                        indexUrl = archivesDirectoryUrl.appendingPathComponent("\(items[items.startIndex])/index.html")
                    }
                    
                    DispatchQueue.main.async {
                        let requestUrl = URLRequest(url: indexUrl)
                        self.webView.load(requestUrl)
                    }
                }
            }
            
        } catch {
            print("[Fplan] Extraction of ZIP archive failed with error:\(error)")
        }
    }
    
    /**
     Stop fplan.
     */
    func destoy() {
        isFplanReady = false
        isFplanDestroyed = true
        
        if var gLocProvider = self.globalLocationProvider {
            gLocProvider.delegate = nil
        }
        
        if var locProvider = self.locationProvider {
            locProvider.delegate = nil
            locProvider.stop()
        }
        
        self.fpReadyCallback = nil
        self.selectBoothCallback = nil
        self.buildDirectionCallback = nil
        self.messageReceivedCallback = nil
        self.config = nil
        
        self.globalLocationProvider = nil
        self.locationProvider = nil
        
        NotificationCenter.default.removeObserver(self)
        
        if let fsWebView = self.webView {
            fsWebView.navigationDelegate = nil
            fsWebView.uiDelegate = nil
            fsWebView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), context: nil)
            fsWebView.configuration.userContentController.removeAllScriptMessageHandlers()
            
            if fsWebView.superview != nil {
                fsWebView.load(URLRequest(url: URL(string: "about:blank")!))
                fsWebView.removeFromSuperview()
            }
            
            self.webView = nil
        }
        
        if self.superview != nil {
            self.removeFromSuperview()
        }
    }
    
    /**
     Select a exhibitor on the floor plan.
     
     **Parameters:**
     - exhibitorName: Exhibitor name
     */
    func selectExhibitor(_ exhibitorName: String?){
        if(exhibitorName != nil && exhibitorName != "") {
            self.webView.evaluateJavaScript("window.___fp && window.___fp.selectExhibitor('\(exhibitorName!)');")
        }
        else {
            self.webView.evaluateJavaScript("window.___fp && window.___fp.selectExhibitor('');")
        }
    }
    
    /**
     Select a booth on the floor plan.
     
     **Parameters:**
     - boothName: Booth name
     */
    func selectBooth(_ boothName: String?){
        if(boothName != nil && boothName != "") {
            self.webView.evaluateJavaScript("window.___fp && window.___fp.selectBooth('\(boothName!)');")
        }
        else {
            self.webView.evaluateJavaScript("window.___fp && window.___fp.selectBooth('');")
        }
    }
    
    /**
     Start the process of building a route from one booth to another.
     After the route is built, the buildDirectionAction callback is called.
     
     **Parameters:**
     - route: Route info
     */
    func selectRoute(_ route: Route?){
        if(route != nil) {
            self.webView.evaluateJavaScript("window.___fp && window.___fp.selectRoute('\(route!.from)', '\(route!.to)', \(route!.exceptInaccessible));")
        }
        else {
            selectBooth(nil)
        }
    }
    
    /**
     Set a blue-dot point.
     
     **Parameters:**
     - position: Coordinates.
     - focus: True - focus the floor plan display on the passed coordinates.
     */
    func setCurrentPosition(_ position: BlueDotPoint?, _ focus: Bool = false){
        if(position != nil) {
            let x = position!.x != nil ? "\(position!.x!)" : "null"
            let y = position!.y != nil ? "\(position!.y!)" : "null"
            
            let z = position!.z != nil ? "'\(position!.z!)'" : "null"
            let angle = position!.angle != nil ? "\(position!.angle!)" : "null"
            
            let lat = position!.latitude != nil ? "\(position!.latitude!)" : "null"
            let lng = position!.longitude != nil ? "\(position!.longitude!)" : "null"
            
            let js =  "window.___fp && window.___fp.selectCurrentPosition({ x: \(x), y: \(y), z: \(z), angle: \(angle), lat: \(lat), lng: \(lng) }, \(focus));"
            self.webView.evaluateJavaScript(js)
        }
        else {
            self.webView.evaluateJavaScript("window.___fp && window.___fp.selectCurrentPosition(null, false);")
        }
    }
    
    /**
     Clear the floor plan
     */
    func clear() {
        selectBooth(nil)
        selectRoute(nil)
        setCurrentPosition(nil)
    }
    
    private func load(_ url: String,
                      locationProvider: LocationProvider? = nil,
                      globalLocationProvider: LocationProvider? = nil,
                      configuration: Configuration? = nil) {
        
        isFplanReady = false
        isFplanDestroyed = false
        
        self.locationProvider = locationProvider
        self.globalLocationProvider = globalLocationProvider
        
        let fileManager = FileManager.default
        let netReachability = NetworkReachability()
        let online = netReachability.checkConnection()
        
        let eventAddress = Helper.getEventAddress(url)
        let eventUrl = "https://\(eventAddress)"
        
        let fplanConfigUrl = URL(string:"\(eventUrl)/\(Constants.fplanConfigPath)")
        let fplanDirectory = Helper.getCacheDirectory().appendingPathComponent("fplan/")
        let eventDirectory = fplanDirectory.appendingPathComponent("\(eventAddress)/")
        let fplanConfigPath = eventDirectory.appendingPathComponent(Constants.fplanConfigPath)
        let zipArchivePath = eventDirectory.appendingPathComponent("archive.zip")
        
        let formatUrl = url.starts(with: "https://") ? url : "https://\(url)"
        
        
        if(online){
            Helper.loadConfiguration(configuration, fplanConfigUrl: fplanConfigUrl!){ config in
                self.config = config
                
                if fileManager.fileExists(atPath: eventDirectory.path){
                    try? fileManager.removeItem(at: eventDirectory)
                }
                
                try? Helper.saveConfiguration(config, fplanConfigPath: fplanConfigPath)
                
                DispatchQueue.main.async {
                    let requestUrl = URLRequest(url: URL(string: formatUrl)!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
                    self.webView.load(requestUrl)
                }
                
                if let zipUrlString = config.zipArchiveUrl,
                   let zipUrl = URL(string: zipUrlString)  {
                    Helper.downloadFile(zipUrl, zipArchivePath)
                }
                
            }
        }
        else {
            let load = {
                if(self.config?.zipArchiveUrl != nil && fileManager.fileExists(atPath: zipArchivePath.path)){
                    let params = Helper.getParams(url)
                    self.openZip(zipArchivePath.path, params: params)
                }
                else {
                    DispatchQueue.main.async {
                        let requestUrl = URLRequest(url: URL(string: formatUrl)!, cachePolicy: .returnCacheDataDontLoad)
                        self.webView.load(requestUrl)
                    }
                }
            }
            
            if(configuration != nil){
                self.config = configuration
                load()
            }
            else {
                if let config = try? Helper.loadConfiguration(fplanConfigPath: fplanConfigPath) {
                    self.config = config
                    load()
                }
                else {
                    print("[Fplan] Offline mode. Failed to read config file from cache.")
                    self.config = Helper.getDefaultConfiguration()
                    load()
                }
            }
        }
    }
}
