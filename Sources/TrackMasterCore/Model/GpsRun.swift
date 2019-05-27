import Foundation

public class GpsRun : Codable, CustomStringConvertible {
    public let points: [GpsPoint]
    public let bounds: Bounds
    public var kilometers: Double = 0.0
    public var seconds: Double = 0.0
    public var secondsIntoTrack: Double = 0.0
    public var kilometersIntoTrack: Double = 0.0
    public var transportationTypes = [TransportationType]()


    init(points: [GpsPoint]) {
        self.points = points

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

                let distanceFromPrevious = Geo.distance(pt1: points[idx - 1], pt2: pt)
                pt.metersFromPrevious = distanceFromPrevious * 1000.0
                kilometers += distanceFromPrevious
                pt.kilometersIntoRun = kilometers

                pt.transportationTypes.forEach { transportTypes[$0.mode, default: 0.0] += $0.probability }
            }

            self.bounds = bnds
            self.transportationTypes = Array(transportTypes.map { (key, value) in
                return TransportationType(probability: value / Double(self.points.count), mode: key)
            }.sorted(by: { $0.probability > $1.probability}).prefix(3))
        } else {
            self.bounds = Bounds()
        }
    }

    public var description: String {
        let startTime = points.first!.time
        return "\(points.count) points, from \(startTime) for \(seconds) seconds and \(Int(kilometers * 1000.0)) meters"
    }
}
