import Foundation
import ExpoFpCommon

public struct Settings {

    public let locationProvider: LocationProvider?
    
    public let useGlobalLocationProvider: Bool
    
    public let focusOnLocation: Bool
    
    public let focusOnFirstLocation: Bool
    
    public let configuration: Configuration?
    
    public init(locationProvider: LocationProvider?) {
        self.init(locationProvider: locationProvider, useGlobalLocationProvider: false, focusOnLocation: false, focusOnFirstLocation: false, configuration: nil)
    }
    
    public init(locationProvider: LocationProvider?, focusOnLocation: Bool) {
        self.init(locationProvider: locationProvider, useGlobalLocationProvider: false, focusOnLocation: focusOnLocation, focusOnFirstLocation: false, configuration: nil)
    }
    
    public init(locationProvider: LocationProvider?, focusOnFirstLocation: Bool) {
        self.init(locationProvider: locationProvider, useGlobalLocationProvider: false, focusOnLocation: false, focusOnFirstLocation: focusOnFirstLocation, configuration: nil)
    }
    
    public init(useGlobalLocationProvider: Bool) {
        self.init(locationProvider: nil, useGlobalLocationProvider: useGlobalLocationProvider, focusOnLocation: false, focusOnFirstLocation: false, configuration: nil)
    }
    
    public init(useGlobalLocationProvider: Bool, focusOnLocation: Bool) {
        self.init(locationProvider: nil, useGlobalLocationProvider: useGlobalLocationProvider, focusOnLocation: focusOnLocation, focusOnFirstLocation: false, configuration: nil)
    }
    
    public init(useGlobalLocationProvider: Bool, focusOnFirstLocation: Bool) {
        self.init(locationProvider: nil, useGlobalLocationProvider: useGlobalLocationProvider, focusOnLocation: false, focusOnFirstLocation: focusOnFirstLocation, configuration: nil)
    }

    public init(locationProvider: LocationProvider?, useGlobalLocationProvider: Bool, focusOnLocation: Bool, focusOnFirstLocation: Bool, configuration: Configuration?) {
        self.locationProvider = locationProvider
        self.useGlobalLocationProvider = useGlobalLocationProvider
        self.focusOnLocation = focusOnLocation
        self.focusOnFirstLocation = focusOnFirstLocation
        self.configuration = configuration
    }
}
