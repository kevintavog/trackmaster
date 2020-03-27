import Foundation

public class GpsPoint: Codable, GeoPoint, CustomStringConvertible {
    public let latitude: Double
    public let longitude: Double
    public let elevation: Double
    public let time: Date
    public let course: Int
    public let speedMs: Double

    // Calculated values
    public var calculatedMeters: Double = 0.0
    public var calculatedSeconds: Double = 0.0
    public var calculatedSpeedMs: Double = 0.0
    public var calculatedSpeedKmh: Double = 0.0
    public var calculatedCourse: Int = 0
    public var calculatedDiffSpeedMs: Double = 0.0


    // Set by analyzers
    public var kilometersIntoSegment: Double = 0
    public var secondsIntoSegment: Double = 0
    public var transportationTypes: [TransportationType] = []

    public init(latitude: Double, longitude: Double, elevation: Double, 
            time: Date, course: Int, speedMs: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.time = time
        self.course = course
        self.speedMs = speedMs
    }

    public func shortTime() -> String {
        return Converter.shortTime(time)
    }

    // Number of seconds between two points, independent of which is earlier
    public func seconds(between: GpsPoint) -> Double {
        return abs(self.time.timeIntervalSince(between.time))
    }

    // Return the distance, in meters, between two points
    public func distanceMeters(between: GpsPoint) -> Double {
        return 1000.0 * distanceKm(between: between)
    }

    // Return the distance, in kilometers, between two points
    public func distanceKm(between: GpsPoint) -> Double {
        return Geo.distance(pt1: self, pt2: between)
    }

    // Return the speed, in kilometers / hour, between two points
    public func speedKmh(between: GpsPoint) -> Double {
        return speedKmh(between: between, distance: Geo.distance(pt1: self, pt2: between))
    }

    public func speedKmh(between: GpsPoint, distance: Double) -> Double {
        return speedKmh(seconds: seconds(between: between), distance: distance)
    }

    public func speedKmh(seconds: Double, distance: Double) -> Double {
        return Converter.speedKph(seconds: seconds, kilometers: distance)
    }

    public func bearing(between: GpsPoint) -> Int {
        return Geo.bearing(pt1: self, pt2: between)
    }

    public var description: String {
        return "\(shortTime()) \(latitude),\(longitude); " +
            "\(calculatedMeters), \(calculatedCourse)°, \(calculatedSpeedMs) m/s, Δ \(calculatedDiffSpeedMs) m/s"
    }
}
