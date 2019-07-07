import Foundation

public class ClusterStop: Codable, CustomStringConvertible {
    public var startTime: Date
    public var endTime: Date
    public var firstPoint: GpsPoint
    public var lastPoint: GpsPoint
    public var countStops: Int
    public var bounds: Bounds
    public var seconds: Double

    public init(points: [GpsPoint]) {
        self.countStops = points.count
        self.seconds = points.last!.seconds(between: points.first!)
        self.firstPoint = points.first!
        self.lastPoint = points.last!
        self.bounds = Bounds(
            minLat: points[0].latitude, minLon: points[0].longitude,
            maxLat: points[0].latitude, maxLon: points[0].longitude)

        for idx in 1..<points.count {
            let cur = points[idx]
            self.bounds.min.latitude = min(cur.latitude, self.bounds.min.latitude)
            self.bounds.min.longitude = min(cur.longitude, self.bounds.min.longitude)
            self.bounds.max.latitude = max(cur.latitude, self.bounds.max.latitude)
            self.bounds.max.longitude = max(cur.longitude, self.bounds.max.longitude)
        }

        self.startTime = points.first!.time
        self.endTime = points.last!.time
    }

    public func extend(point: GpsPoint) {
        if point.time < self.startTime {
            self.startTime = point.time
            self.firstPoint = point
        }
        if point.time > self.endTime {
            self.endTime = point.time
            self.lastPoint = point
        }
        self.countStops += 1
        self.seconds = abs(self.startTime.timeIntervalSince(self.endTime))
        bounds.min.latitude = min(point.latitude, bounds.min.latitude)
        bounds.min.longitude = min(point.longitude, bounds.min.longitude)
        bounds.max.latitude = max(point.latitude, bounds.max.latitude)
        bounds.max.longitude = max(point.longitude, bounds.max.longitude)
    }

    public func contains(point: GpsPoint) -> Bool {
        return point.time >= startTime && point.time <= endTime
    }

    public var description: String {
        return "\(startTime), \(seconds) seconds, \(countStops) stops"
    }
}
