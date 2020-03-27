import Foundation

public class GpsWaypoint : CustomStringConvertible {
    public let latitude: Double
    public let longitude: Double
    public let elevation: Double
    public let time: Date
    public let name: String
    public var stop: CalculatedStop? = nil


    public init(_ latitude: Double, _ longitude: Double, _ elevation: Double,
            _ time: Date, _ name: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.time = time
        self.name = name
    }

    public func shortTime() -> String {
        return Converter.shortTime(time)
    }

    public var description: String {
        return "\(shortTime()) \(latitude),\(longitude); \(name)"
    }
}
