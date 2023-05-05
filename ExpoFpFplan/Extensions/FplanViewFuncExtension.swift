import Foundation
import ExpoFpCommon

public extension FplanView {
    /**
     Set a callback that is called after the plan is initialized.
     
     **Parameters:**
     - callback: Callback
     */
    func onFpReady(_ callback: @escaping () -> Void) -> FplanView {
        self.state.fplanUiKitView?.setOnFpReadyCallback(callback)
        return self
    }
    
    /**
     Set a callback that is called after selecting a booth on the plan.
     
     **Parameters:**
     - callback: Callback
     */
    func onBoothClick(_ callback: @escaping (_ id: String, _ name: String) -> Void) -> FplanView {
        self.state.fplanUiKitView?.setOnBoothClickCallback(callback)
        return self
    }
    
    /**
     Set a callback that is called after the route is built.
     
     **Parameters:**
     - callback: Callback
     */
    func onBuildDirection(_ callback: @escaping (_ direction: Direction) -> Void) -> FplanView {
        self.state.fplanUiKitView?.setOnBuildDirectionCallback(callback)
        return self
    }
    
    /**
     Set a callback that is called after receiving a message from the plan.
     
     **Parameters:**
     - callback: Callback
     */
    func onMessageReceived(_ callback: @escaping (_ message: String) -> Void) -> FplanView {
        self.state.fplanUiKitView?.setOnMessageReceivedCallback(callback)
        return self
    }
    
    /**
     Starts the plan loading process.
     
     **Parameters:**
     - url: Plan URL
     */
    func load(_ url: String){
        self.state.fplanUiKitView?.load(url)
    }
    
    /**
     Starts the plan loading process.
     
     **Parameters:**
     - url: Plan URL.
     - locationProvider: Сoordinate provider.
     */
    func load(_ url: String, locationProvider: LocationProvider? = nil) {
        self.state.fplanUiKitView?.load(url, locationProvider: locationProvider)
    }
    
    /**
     Start the plan loading process.
     
     **Parameters:**
     - url: Plan URL.
     - locationProvider: Сoordinate provider.
     - configuration: Plan config.
     */
    func load(_ url: String, locationProvider: LocationProvider? = nil, configuration: Configuration? = nil) {
        self.state.fplanUiKitView?.load(url, locationProvider: locationProvider, configuration: configuration)
    }
    
    /**
     Start the plan loading process.
     
     **Parameters:**
     - url: Plan URL.
     - useGlobalLocationProvider: Flag indicating whether to use the global coordinate provider.
     */
    func load(_ url: String, useGlobalLocationProvider: Bool = false) {
        self.state.fplanUiKitView?.load(url, useGlobalLocationProvider: useGlobalLocationProvider)
    }
    
    /**
     Start the plan loading process.
     
     **Parameters:**
     - url: Plan URL.
     - useGlobalLocationProvider: Flag indicating whether to use the global coordinate provider.
     - configuration: Plan config.
     */
    func load(_ url: String, useGlobalLocationProvider: Bool = false, configuration: Configuration? = nil) {
        self.state.fplanUiKitView?.load(url, useGlobalLocationProvider: useGlobalLocationProvider, configuration: configuration)
    }
    
    /**
     Stop fplan.
     */
    func destoy() {
        self.state.fplanUiKitView?.destoy()
    }
    
    /**
     Select a exhibitor on the floor plan.
     
     **Parameters:**
     - exhibitorName: Exhibitor name
     */
    func selectExhibitor(_ exhibitorName: String?){
        self.state.fplanUiKitView?.selectExhibitor(exhibitorName)
    }
    
    /**
     Select a booth on the floor plan.
     
     **Parameters:**
     - boothName: Booth name
     */
    func selectBooth(_ boothName: String?){
        self.state.fplanUiKitView?.selectBooth(boothName)
    }
    
    /**
     Start the process of building a route from one booth to another.
     After the route is built, the buildDirectionAction callback is called.
     
     **Parameters:**
     - route: Route info
     */
    func selectRoute(_ route: Route?){
        self.state.fplanUiKitView?.selectRoute(route)
    }
    
    /**
     Set a blue-dot point.
     
     **Parameters:**
     - position: Coordinates.
     - focus: True - focus the floor plan display on the passed coordinates.
     */
    func setCurrentPosition(_ position: BlueDotPoint?, _ focus: Bool = false){
        self.state.fplanUiKitView?.setCurrentPosition(position, focus)
    }
    
    /**
     Clear the floor plan
     */
    func clear() {
        self.state.fplanUiKitView?.clear()
    }
}
