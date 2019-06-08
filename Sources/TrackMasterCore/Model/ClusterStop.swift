import Foundation

public class ClusterStop: Codable, CustomStringConvertible {
    public var points: [GpsPoint]
    public var bounds: Bounds
    public var seconds: Double
    public var endToEndMeters: Int
    public var meters: Int

    public init(points: [GpsPoint]) {
        self.points = points
        self.seconds = points.last!.seconds(between: points.first!)
        self.endToEndMeters = Int(1000 * points.last!.distanceKm(between: points.first!))
        let bnds = Bounds(minLat: points[0].latitude, minLon: points[0].longitude,
            maxLat: points[0].latitude, maxLon: points[0].longitude)
        var m = 0
        for idx in 1..<points.count {
            let cur = points[idx]
            m += points[idx-1].distanceMeters(between: cur)
            bnds.min.latitude = min(cur.latitude, bnds.min.latitude)
            bnds.min.longitude = min(cur.longitude, bnds.min.longitude)
            bnds.max.latitude = max(cur.latitude, bnds.max.latitude)
            bnds.max.longitude = max(cur.longitude, bnds.max.longitude)
        }
        self.meters = m
        self.bounds = bnds
    }

    public func extend(point: GpsPoint) {
        if point.time < points.first!.time {
            points.insert(point, at: 0)
        } else if point.time > points.last!.time {
            points.append(point)
        }

        self.seconds = points.last!.seconds(between: points.first!)
        self.endToEndMeters = Int(1000 * points.last!.distanceKm(between: points.first!))
        bounds.min.latitude = min(point.latitude, bounds.min.latitude)
        bounds.min.longitude = min(point.longitude, bounds.min.longitude)
        bounds.max.latitude = max(point.latitude, bounds.max.latitude)
        bounds.max.longitude = max(point.longitude, bounds.max.longitude)
    }

    public func contains(point: GpsPoint) -> Bool {
        return point.time >= points.first!.time && point.time <= points.last!.time
    }

    public var description: String {
        return "\(points.first!.time), \(seconds) seconds, \(meters) meters, \(points.count) points "
    }
}
