import Foundation

public protocol GeoPoint {
    var latitude: Double { get }
    var longitude: Double { get }
}

public class GeoPointInstance: GeoPoint, Codable, CustomStringConvertible {
    public var latitude: Double
    public var longitude: Double

    public init(point: GeoPoint) {
        self.latitude = point.latitude
        self.longitude = point.longitude
    }

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public init() {
        self.latitude = 0.0
        self.longitude = 0.0
    }

    public var description: String {
        return "\(latitude), \(longitude)"
    }

    enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lon"
    }
}

public struct GeoLine {
    public let start: GeoPoint
    public let end: GeoPoint

    init(start: GeoPoint, end: GeoPoint) {
        self.start = start
        self.end = end
    }

    func mid() -> GeoPoint {
        return GeoPointInstance(
            latitude: start.latitude + (abs(end.latitude - start.latitude) / 2),
            longitude: start.longitude + (abs(end.longitude - start.longitude) / 2))
    }
}

public struct GeoRectangle {
    public let minLat: Double
    public let minLon: Double
    public let maxLat: Double
    public let maxLon: Double

    init(center: GeoPoint, distanceMeters: Double) {
        let (latOffset, lonOffset) = Geo.meterOffsetAt(
            distanceMeters: distanceMeters,
            latitude: center.latitude,
            longitude: center.longitude)
        self.minLat = center.latitude - latOffset
        self.minLon = center.longitude - lonOffset
        self.maxLat = center.latitude + latOffset
        self.maxLon = center.longitude + lonOffset
    }

    init(minLat: Double, minLon: Double, maxLat: Double, maxLon: Double) {
        self.minLat = minLat
        self.minLon = minLon
        self.maxLat = maxLat
        self.maxLon = maxLon
    }

    public func within(point: GeoPoint) -> Bool {
        return point.latitude > self.minLat && point.longitude < self.maxLat &&
            point.longitude > self.minLon && point.longitude < self.maxLat
    }
}

