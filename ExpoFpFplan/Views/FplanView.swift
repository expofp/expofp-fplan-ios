import Foundation
import SwiftUI
import WebKit
import ExpoFpCommon

final class FplanViewState: ObservableObject {
    var fplanUiKitView: UIFplanView? = nil
}

public struct FplanView: UIViewRepresentable {
    
    @ObservedObject var state = FplanViewState()

    public init() {
    }
    
    public func makeUIView(context: Context) -> UIFplanView {
        let view = UIFplanView()
        state.fplanUiKitView = view
        return view
    }
    
    public func updateUIView(_ webView: UIFplanView, context: Context) {
    }
}
