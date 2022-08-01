import Foundation
import WebKit
import UniformTypeIdentifiers
import ExpoFpCommon

class FSWebViewController: UIViewController, WKURLSchemeHandler, WKNavigationDelegate, LocationProviderDelegate {
    
    var wkWebView: WKWebView? = nil
    
    var provider: LocationProvider? = nil
    
    var selectedBooth: String?
    var route: Route?
    var currentPosition: BlueDotPoint?
    
    var expoCacheDirectory: String = ""
    var expoUrl: String = ""
    var config: Configuration? = nil
    
    var loadedAction: (() -> Void)? = nil
    
    func setExpo(_ expoUrl: String, _ expoCacheDirectory: String, _ config: Configuration, _ loadedAction: (() -> Void)? = nil){
        self.expoUrl = expoUrl
        self.expoCacheDirectory = expoCacheDirectory
        self.config = config
        self.loadedAction = loadedAction
    }
    
    func setLocationProvider(provider: LocationProvider?){
        if(self.provider == nil && provider != nil){
            self.provider = provider
            
            self.provider?.addDelegate(self)
            self.provider?.start()
        }
        else if(self.provider != nil && provider == nil) {
            self.provider = nil
            
            self.provider?.removeDelegate(self)
            self.provider?.stop()
        }
    }
    
    func selectBooth(_ boothName: String?){
        self.selectedBooth = boothName
        
        if(boothName != nil && boothName != "") {
            wkWebView?.evaluateJavaScript("window.floorplan?.selectBooth('\(boothName!)');")
        }
        else {
            wkWebView?.evaluateJavaScript("window.floorplan?.selectBooth('');")
        }
    }
    
    func buildRoute(_ route: Route?){
        self.route = route
        
        if(route != nil) {
            wkWebView?.evaluateJavaScript("window.floorplan?.selectRoute('\(route!.from)', '\(route!.to)', \(route!.exceptInaccessible));")
        }
        else {
            wkWebView?.evaluateJavaScript("window.floorplan?.selectRoute(null, null, false);")
        }
    }
    
    func setCurrentPosition(_ position: BlueDotPoint?, _ focus: Bool = false){
        self.currentPosition = position
        
        if(position != nil) {
            let x = position!.x != nil ? "\(position!.x!)" : "null"
            let y = position!.y != nil ? "\(position!.y!)" : "null"
            
            let z = position!.z != nil ? "'\(position!.z!)'" : "null"
            let angle = position!.angle != nil ? "\(position!.angle!)" : "null"
            
            let lat = position!.latitude != nil ? "\(position!.latitude!)" : "null"
            let lng = position!.longitude != nil ? "\(position!.longitude!)" : "null"
            
            wkWebView?.evaluateJavaScript(
                "window.floorplan?.selectCurrentPosition({ x: \(x), y: \(y), z: \(z), angle: \(angle), lat: \(lat), lng: \(lng) }, \(focus));")
        }
        else {
            wkWebView?.evaluateJavaScript("window.floorplan?.selectCurrentPosition(null, false);")
        }
    }
    
    func didUpdateLocation(location: Location) {
        self.currentPosition = BlueDotPoint(x: location.x, y: location.y, z: location.z, angle: location.angle,
                                            latitude: location.latitude, longitude: location.longitude)
        
        setCurrentPosition(self.currentPosition, false)
    }
    
    func didStartSuccess() {
    }
    
    func didStartFailure(reason: String) {
    }
    
    func didStopSuccess() {
    }
    
    func didStopFailure(reason: String) {
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if(navigationAction.navigationType == WKNavigationType.other){
            decisionHandler(.allow)
            return
        }
        
        if let url = navigationAction.request.url {
            if url.scheme == "https" || url.scheme == "http" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        if(urlSchemeTask.request.url == nil || urlSchemeTask.request.url?.scheme != Constants.scheme){
            return
        }
        
        var realPath = urlSchemeTask.request.url!.absoluteString.replacingOccurrences(of: Constants.scheme, with: "file")
        if let index = realPath.firstIndex(of: "?"){
            realPath = String(realPath[..<index])
        }
        
        let realUrl = URL.init(string: realPath)
        
        if(!FileManager.default.fileExists(atPath: realUrl!.path)){
            let dir = realUrl!.deletingLastPathComponent().path
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            
            let pth = realPath.lowercased().replacingOccurrences(of: expoCacheDirectory.lowercased(), with: "")
            let reqUrl = expoUrl + pth
            
            Helper.downloadFile(URL.init(string: reqUrl)!, realUrl!){
                self.setData(urlSchemeTask: urlSchemeTask, dataURL: realUrl!)
            }
        }
        else {
            setData(urlSchemeTask: urlSchemeTask, dataURL: realUrl!)
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            if(loadedAction != nil && wkWebView != nil && wkWebView!.estimatedProgress == 1.0 ){
                loadedAction!();
            }
        }
    }
    
    private func setData(urlSchemeTask: WKURLSchemeTask, dataURL: URL){
        let data = try? Data(contentsOf: dataURL)
        if(data == nil) {
            let urlResponse = URLResponse(url: urlSchemeTask.request.url!, mimeType: nil, expectedContentLength: -1, textEncodingName: "gzip")
            urlSchemeTask.didReceive(urlResponse)
            urlSchemeTask.didFinish()
            return
        }
        
        let mimeType = dataURL.mimeType()
        let urlResponse = URLResponse(url: urlSchemeTask.request.url!, mimeType: mimeType, expectedContentLength: data!.count, textEncodingName: "gzip")
        urlSchemeTask.didReceive(urlResponse)
        
        urlSchemeTask.didReceive(data!)
        urlSchemeTask.didFinish()
    }
}

