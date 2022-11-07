import Foundation
import WebKit

//@available(iOS 13.0, *)
class DetailsHandler : NSObject, WKScriptMessageHandler {
    
    private let detailsHandler: (_ details: Details?) -> Void
    
    public init(_ detailsHandler: ((_ details: Details?) -> Void)!) {
        self.detailsHandler = detailsHandler
        super.init()
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let json = message.body as? String{
            let decoder = JSONDecoder()
            
            guard let details = try? decoder.decode(Details.self, from: json.data(using: .utf8)!) else {
                detailsHandler(nil)
                return
            }
            
            detailsHandler(details)
        }
        
        detailsHandler(nil)
    }
}
