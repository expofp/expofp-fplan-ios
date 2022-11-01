import Foundation
import WebKit

@available(iOS 13.0, *)
class MessageHandler : NSObject, WKScriptMessageHandler {
    private let webView: FSWebView
    private let messageReceivedHandler: (_ webView: FSWebView, _ message: String) -> Void
    
    public init(_ webView: FSWebView, _ messageReceivedHandler: ((_ webView: FSWebView, _ message: String) -> Void)!) {
        self.webView = webView
        self.messageReceivedHandler = messageReceivedHandler
        super.init()
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let content = message.body as? String {
            messageReceivedHandler(webView, content)
        }
    }
}
