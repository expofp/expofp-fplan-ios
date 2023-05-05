import Foundation
import ExpoFpCommon

extension UIFplanView : LocationProviderDelegate {
    
    public func didUpdateLocation(location: ExpoFpCommon.Location) {
        let currentPosition = BlueDotPoint(x: location.x, y: location.y, z: location.z, angle: location.angle,
                                            latitude: location.latitude, longitude: location.longitude)
        
        self.setCurrentPosition(currentPosition, false)
    }
    
    public func didStartSuccess() {
    }
    
    public func didStartFailure(reason: String) {
    }
    
    public func didStopSuccess() {
    }
    
    public func didStopFailure(reason: String) {
    }
}
