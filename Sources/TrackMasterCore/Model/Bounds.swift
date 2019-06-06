import Foundation

public struct Bounds: Codable {
    public var min: GeoPointInstance
    public var max: GeoPointInstance

    public init() {
        self.min = GeoPointInstance(latitude: 90.0, longitude: 180.0)
        self.max = GeoPointInstance(latitude: -90.0, longitude: -180.0)        
    }

    public init(minLat: Double, minLon: Double, maxLat: Double, maxLon: Double) {
        self.min = GeoPointInstance(latitude: minLat, longitude: minLon)
        self.max = GeoPointInstance(latitude: maxLat, longitude: maxLon)        
    }
}
