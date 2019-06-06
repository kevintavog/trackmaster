import Foundation

public class GpsRun : Codable, CustomStringConvertible {
    public let points: [GpsPoint]
    public let bounds: Bounds
    public var kilometers: Double = 0.0
    public var seconds: Double = 0.0
    public var secondsIntoTrack: Double = 0.0
    public var kilometersIntoTrack: Double = 0.0
    public var transportationTypes = [TransportationType]()
    public let excessive: Int


    public init(points: [GpsPoint]) {
        self.points = points

points[0].prevSpeedChange = 0
points[0].prevCourseChange = 0
        if points.count > 0 {
            let bnds = Bounds()
            var transportTypes = [TransportationMode: Double]()
            bnds.min.latitude = points[0].latitude
            bnds.min.longitude = points[0].longitude
            bnds.max.latitude = points[0].latitude
            bnds.max.longitude = points[0].longitude
            kilometers = 0.0
            seconds = 0.0

            for idx in 1..<points.count {
                let pt = points[idx]
                bnds.min.latitude = min(pt.latitude, bnds.min.latitude)
                bnds.min.longitude = min(pt.longitude, bnds.min.longitude)
                bnds.max.latitude = max(pt.latitude, bnds.max.latitude)
                bnds.max.longitude = max(pt.longitude, bnds.max.longitude)
                seconds = points[0].seconds(between: pt)
                pt.secondsIntoRun = seconds

                kilometers += pt.kmFromPrevious
                pt.kilometersIntoRun = kilometers

// print("\(pt.time) - average: \(pt.movingAverageKmH) speed: \(pt.calculatedSpeedKmHFromPrevious)," +
//         " course: \(pt.calculatedCourseFromPrevious)," +
//         " distance: \(Int(pt.kmFromPrevious * 1000.0 * 100.0)) centimeters, seconds: \(pt.secondsFromPrevious)" +
//         " - problems: \(pt.problems)")

                pt.transportationTypes.forEach { transportTypes[$0.mode, default: 0.0] += $0.probability }

pt.prevSpeedChange = abs(pt.calculatedSpeedKmHFromPrevious - points[idx - 1].calculatedSpeedKmHFromPrevious)
pt.prevCourseChange = Geo.bearingDelta(pt.calculatedCourseFromPrevious, points[idx - 1].calculatedCourseFromPrevious)
            }

var calc = 0
points.forEach { if $0.prevCourseChange >= 90 { calc += 1}; if $0.prevSpeedChange > 9.9 { calc += 1} }
// print(" \(points[0].time); of \(points.count), excessive: \(excessive)")
self.excessive = calc

            self.bounds = bnds
            self.transportationTypes = Array(transportTypes.map { (key, value) in
                return TransportationType(probability: value / Double(self.points.count), mode: key)
            }.sorted(by: { $0.probability > $1.probability}).prefix(3))
        } else {
self.excessive = 0
            self.bounds = Bounds()
        }
    }

    public var description: String {
        let startTime = points.first!.time
        // let crowDistanceMeters = Int(points.first!.distanceKm(between: points.last!) * 1000)
        // let distanceCrowRatio = Int(100 * points.first!.distanceKm(between: points.last!) / kilometers)
        return "\(points.count) points, from \(startTime) for \(seconds) seconds " +
            "and \(Int(kilometers * 1000.0)) meters, " +
            // "crow: \(crowDistanceMeters) meters (\(distanceCrowRatio)), " +
            "\(Double(Int(1000 * Converter.speedKph(seconds: seconds, kilometers: kilometers))) / 1000.0) km/hour"
    }
}
