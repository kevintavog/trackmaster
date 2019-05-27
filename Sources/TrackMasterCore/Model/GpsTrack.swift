import Foundation

public class GpsTrack : Codable, CustomStringConvertible {
    public let runs: [GpsRun]
    public let bounds: Bounds
    public let durationSeconds: Double
    public let distanceKilometers: Double

    init(runs: [GpsRun]) {
        self.runs = runs

        let bnds = Bounds()

        var secondsIntoTrack = 0.0
        var kilometersIntoTrack = 0.0
        for r in runs {
            r.secondsIntoTrack = secondsIntoTrack
            secondsIntoTrack += r.seconds
            r.kilometersIntoTrack = kilometersIntoTrack
            kilometersIntoTrack += r.kilometers

            bnds.min.latitude = min(bnds.min.latitude, r.bounds.min.latitude)
            bnds.min.longitude = min(bnds.min.longitude, r.bounds.min.longitude)
            bnds.max.latitude = max(bnds.max.latitude, r.bounds.max.latitude)
            bnds.max.longitude = max(bnds.max.longitude, r.bounds.max.longitude)
        }

        self.bounds = bnds
        self.durationSeconds = secondsIntoTrack
        self.distanceKilometers = kilometersIntoTrack
     }

    public var description: String {
        let startTime = runs.first!.points.first!.time
        return "\(runs.count) runs, from \(startTime) for \(durationSeconds) seconds and \(Int(distanceKilometers * 1000.0)) meters"
    }
}
