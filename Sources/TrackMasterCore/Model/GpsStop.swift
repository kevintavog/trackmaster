import Foundation

public class GpsStop: Codable, CustomStringConvertible {
    public var startTime: Date
    public var endTime: Date
    public var firstPoint: GpsPoint
    public var lastPoint: GpsPoint
    public var countPoints: Int
    public var bounds: Bounds
    public var seconds: Double
    public var secondsNotMoving: Double

    public init(points: [GpsPoint]) {
        self.countPoints = points.count
        self.firstPoint = points.first!
        self.lastPoint = points.last!
        self.seconds = points.last!.seconds(between: points.first!)
        self.secondsNotMoving = self.seconds
        self.bounds = Bounds(minLat: points[0].latitude, minLon: points[0].longitude,
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

    public func extend(stop: GpsStop) {
        if stop.startTime < self.startTime {
            self.startTime = stop.startTime
            self.firstPoint = stop.firstPoint
        }
        if stop.startTime > self.endTime {
            self.endTime = stop.startTime
            self.lastPoint = stop.lastPoint
        }
        self.countPoints += stop.countPoints
        self.seconds = abs(self.startTime.timeIntervalSince(self.endTime))
        self.secondsNotMoving += stop.secondsNotMoving
        self.bounds.min.latitude = min(stop.bounds.min.latitude, self.bounds.min.latitude)
        self.bounds.min.longitude = min(stop.bounds.min.longitude, self.bounds.min.longitude)
        self.bounds.max.latitude = max(stop.bounds.max.latitude, self.bounds.max.latitude)
        self.bounds.max.longitude = max(stop.bounds.max.longitude, self.bounds.max.longitude)
    }

    public func contains(point: GpsPoint) -> Bool {
        return point.time >= startTime && point.time <= endTime
    }

    public var description: String {
        return "\(startTime), \(seconds) seconds, \(countPoints) points"
    }
}
