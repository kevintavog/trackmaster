import Foundation

public enum GpsObjectType: String {
    case segment, stop
}

public protocol GpsObject {
    var objectType: GpsObjectType { get }

    var seconds: Double { get }
    var distanceMeters: Double { get }
    var speedMs: Double { get }

    var beginLatitude: Double { get }
    var beginLongitude: Double { get }
    var beginTime: Date { get }

    var finishLatitude: Double { get }
    var finishLongitude: Double { get }
    var finishTime: Date { get }

    var label: String { get }
}

public extension GpsObject {
    func metersBetween(_ other: GpsObject) -> Double {
        var km = 0.0
        if self.beginTime < other.beginTime {
            km = Geo.distance(
                lat1: finishLatitude, lon1: finishLongitude,
                lat2: other.beginLatitude, lon2: other.beginLongitude)
        } else {
            km = Geo.distance(
                lat1: beginLatitude, lon1: beginLongitude,
                lat2: other.finishLatitude, lon2: other.finishLongitude)
        }
        return km * 1000.0
    }

    // Return the number of seconds of the closest end of the other object
    func secondsBetween(_ other: GpsObject) -> Double {
        return min(
            Converter.secondsBetween(beginTime, other.finishTime),
            Converter.secondsBetween(finishTime, other.beginTime))
    }

    func shortBeginTime() -> String {
        return Converter.shortTime(beginTime)
    }

    func shortFinishTime() -> String {
        return Converter.shortTime(finishTime)
    }

    func centroid() -> GeoPoint {
        let lat = (beginLatitude + finishLatitude) / 2
        let lon = (beginLongitude + finishLongitude) / 2
        return GeoPointInstance(latitude: lat, longitude: lon)
    }

    // Return the number of meters from the center of this object to the other object.
    func metersBetweenCentroid(_ other: GpsObject) -> Double {
        let km = Geo.distance(
            lat1: (beginLatitude + finishLatitude) / 2, lon1: (beginLongitude + finishLongitude) / 2,
            lat2: (other.beginLatitude + other.finishLatitude) / 2, lon2: (other.beginLongitude + other.finishLongitude) / 2)
        return km * 1000.0
    }
}
