import Foundation

public class GpsStop: Codable, CustomStringConvertible {
    public let points: [GpsPoint]
    public let seconds: Double
    public let meters: Int

    public init(points: [GpsPoint], extraSeconds: Double, extraMeters: Int) {
        self.points = points
        self.seconds = extraSeconds + points.last!.seconds(between: points.first!)
        var m = extraMeters
        for idx in 1..<points.count {
            m += Int(Geo.distance(pt1: points[idx-1], pt2: points[idx]) * 1000)
        }
        self.meters = m
    }

    public var description: String {
        return "\(points.first!.time), \(seconds), seconds, \(meters) meters"
    }
}
