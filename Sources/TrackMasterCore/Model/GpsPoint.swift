import Foundation

public enum PointProblem: String, Codable {
    case noSpeed = "no speed"
    case tooFast = "too fast"
    case substantialCourseChange = "substantial course change"
    case substantialSpeedChange = "substantial speed change"
}


public class GpsPoint: Codable, GeoPoint, CustomStringConvertible {
    public let latitude: Double
    public let longitude: Double
    public let elevation: Double
    public let time: Date
    public let course: Int
    public let speedMs: Double
    public let speedKmH: Double

    // Set by analyzers
    public var calculatedCourseFromPrevious: Int = 0
    public var kmFromPrevious: Double = 0
    public var secondsFromPrevious: Double = 0
    public var calculatedSpeedKmHFromPrevious: Double = 0
    public var movingAverageKmH: Double = 0
    public var kilometersIntoRun: Double = 0
    public var secondsIntoRun: Double = 0
    public var problems: [PointProblem] = []
    public var transportationTypes: [TransportationType] = []

    public var prevSpeedChange: Double = 0
    public var prevCourseChange: Int = 0

    static private var _dateTimeFormatter: DateFormatter?
    static public var dateTimeFormatter: DateFormatter {
        get {
            if GpsPoint._dateTimeFormatter == nil {
                let dt = DateFormatter()
                dt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                dt.timeZone = TimeZone(secondsFromGMT: 0)
                GpsPoint._dateTimeFormatter = dt
            }
            return GpsPoint._dateTimeFormatter!
        }
    }

    public init(latitude: Double, longitude: Double, elevation: Double, 
            time: Date, course: Int, speedMs: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.time = time
        self.course = course
        self.speedMs = speedMs

        self.speedKmH = Converter.metersPerSecondToKilometersPerHour(metersSecond: self.speedMs)
    }

    public func timeString() -> String {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: time)
        return String(format: "%02d:%02d:%02d", components.hour!, components.minute!, components.second!)
    }

    // Number of seconds between two points, independent of which is earlier
    public func seconds(between: GpsPoint) -> Double {
        return abs(self.time.timeIntervalSince(between.time))
    }

    // Return the distance, in meters, between two points
    public func distanceMeters(between: GpsPoint) -> Int {
        return Int(1000 * distanceKm(between: between))
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

    public var description: String {
        return "\(latitude), \(longitude), km/h: \(speedKmH), @\(time)"
    }

    var dms: String {
        let latitudeNorthOrSouth = latitude < 0 ? "S" : "N"
        let longitudeEastOrWest = longitude < 0 ? "W" : "E"
        return "\(toDms(latitude)) \(latitudeNorthOrSouth), \(toDms(longitude)) \(longitudeEastOrWest)"
    }

    fileprivate func toDms(_ geo: Double) -> String {
        var g = geo
        if (g < 0.0) {
            g *= -1.0
        }

        let degrees = Int(g)
        let minutesDouble = (g - Double(degrees)) * 60.0
        let minutesInt = Int(minutesDouble)
        let seconds = (minutesDouble - Double(minutesInt)) * 60.0

        return String(format: "%.2d° %.2d' %.2f\"", degrees, minutesInt, seconds)
    }
}
