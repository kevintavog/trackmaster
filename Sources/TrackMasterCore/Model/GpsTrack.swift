import Foundation

public class GpsTrack: CustomStringConvertible {
    public let segments: [GpsSegment]
    public let bounds: Bounds
    public let seconds: Double
    public let kilometers: Double

    init(segments: [GpsSegment]) {
        self.segments = segments

        let bnds = Bounds()

        var secondsIntoTrack = 0.0
        var kilometersIntoTrack = 0.0
        for s in segments {
            s.secondsIntoTrack = secondsIntoTrack
            secondsIntoTrack += s.seconds
            s.kilometersIntoTrack = kilometersIntoTrack
            kilometersIntoTrack += s.kilometers

            bnds.min.latitude = min(bnds.min.latitude, s.bounds.min.latitude)
            bnds.min.longitude = min(bnds.min.longitude, s.bounds.min.longitude)
            bnds.max.latitude = max(bnds.max.latitude, s.bounds.max.latitude)
            bnds.max.longitude = max(bnds.max.longitude, s.bounds.max.longitude)
        }

        self.bounds = bnds
        self.seconds = secondsIntoTrack
        self.kilometers = kilometersIntoTrack
    }

    public var description: String {
        let startTime = segments.first!.points.first!.time
        return "\(segments.count) segments, from \(startTime) for \(seconds) seconds and \(Int(kilometers * 1000.0)) meters"
    }
}
