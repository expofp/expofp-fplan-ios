import Foundation
import SwiftUI
import WebKit
import ExpoFpCommon

final class FplanViewState: ObservableObject {
    var fplanUiKitView: FplanUiKitView? = nil
}

public struct FplanView: UIViewRepresentable {
    
    @ObservedObject var state = FplanViewState()

    public init() {
    }
    
    public func makeUIView(context: Context) -> FplanUiKitView {
        let view = FplanUiKitView()
        state.fplanUiKitView = view
        return view
    }
    
    public func updateUIView(_ webView: FplanUiKitView, context: Context) {
    }
}
