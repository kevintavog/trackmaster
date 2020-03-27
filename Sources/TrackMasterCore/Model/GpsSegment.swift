import Foundation

public class GpsSegment : GpsObject, Codable, CustomStringConvertible {
    public let points: [GpsPoint]
    public let bounds: Bounds
    public let kilometers: Double
    public let kmh: Double
    public var secondsIntoTrack: Double = 0.0
    public var kilometersIntoTrack: Double = 0.0
    public var transportationTypes = [TransportationType]()


    public var objectType: GpsObjectType { get { return .segment } }
    public var beginLatitude: Double { get { return points.first!.latitude } }
    public var beginLongitude: Double { get { return points.first!.longitude } }
    public var beginTime: Date { get { return points.first!.time } }
    public var finishLatitude: Double { get { return points.last!.latitude } }
    public var finishLongitude: Double { get { return points.last!.longitude }}
    public var finishTime: Date { get { return points.last!.time } }
    public var label: String { get { return "\(points.count)" } }

    public var description: String {
        let startTime = points.first!.time
        let endTime = points.last!.time
        return "\(points.count) points, from \(startTime) for \(endTime); \(kilometers) km; \(kmh) kmh"
    }

    public var bearing: Int {
        return Geo.bearing(pt1: points.first!, pt2: points.last!)
    }

    public var distanceMeters: Double {
        return points.reduce(0.0) { $0 + $1.calculatedMeters }
    }

    public var seconds: Double {
        if points.count == 0 {
            return 0.0
        }
        return points.first!.seconds(between: points.last!)
    }

    public var speedMs: Double {
        return distanceMeters / seconds
    }



    public init(points: [GpsPoint]) {
        self.points = points

        if points.count > 0 {
            let bnds = Bounds()
            var transportTypes = [TransportationMode: Double]()
            bnds.min.latitude = points[0].latitude
            bnds.min.longitude = points[0].longitude
            bnds.max.latitude = points[0].latitude
            bnds.max.longitude = points[0].longitude
            var km = 0.0

            for idx in 0..<points.count {
                let pt = points[idx]
                bnds.min.latitude = min(pt.latitude, bnds.min.latitude)
                bnds.min.longitude = min(pt.longitude, bnds.min.longitude)
                bnds.max.latitude = max(pt.latitude, bnds.max.latitude)
                bnds.max.longitude = max(pt.longitude, bnds.max.longitude)
                pt.secondsIntoSegment = points[0].seconds(between: pt)

                km += pt.calculatedMeters / 1000.0
                pt.kilometersIntoSegment = km
                pt.transportationTypes.forEach { transportTypes[$0.mode, default: 0.0] += $0.probability }
            }

            self.kilometers = km
            self.kmh = Converter.speedKph(seconds: points.first!.seconds(between: points.last!), kilometers: kilometers)
            self.bounds = bnds
            self.transportationTypes = Array(transportTypes.map { (key, value) in
                return TransportationType(probability: value / Double(self.points.count), mode: key)
            }.sorted(by: { $0.probability > $1.probability}).prefix(3))
        } else {
            self.bounds = Bounds()
            self.kilometers = 0
            self.kmh = 0
        }
    }
}
