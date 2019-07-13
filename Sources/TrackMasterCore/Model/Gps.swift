import Foundation

public class Gps: Codable, CustomStringConvertible {
    public let id: String
    public let path: String
    public let tracks: [GpsTrack]
    public let stops: [GpsStop]
    public let removedRuns: [GpsRun]
    public let timezoneInfo: TimezoneInfo
    public let startTime: Date
    public let endTime: Date
    public let distanceKilometers: Double
    public let durationSeconds: Double
    public let movingSeconds: Double
    public let bounds: Bounds


    public init(path: String, 
            tracks: [GpsTrack], removedRuns: [GpsRun],
            stops: [GpsStop],
            tzInfo: TimezoneInfo) {
        self.path = path
        self.id = path.urlEscape()
        self.tracks = tracks
        self.stops = stops
        self.removedRuns = removedRuns
        self.timezoneInfo = tzInfo
        self.startTime = tracks.first!.runs.first!.points.first!.time
        self.endTime = tracks.last!.runs.last!.points.last!.time
        self.durationSeconds = tracks.first!.runs.first!.points.first!.seconds(between: tracks.last!.runs.last!.points.last!)

        var distance = 0.0
        var seconds = 0.0
        let bnds = Bounds()
        for t in tracks {
            distance += t.distanceKilometers
            seconds += t.durationSeconds
            bnds.min.latitude = min(bnds.min.latitude, t.bounds.min.latitude)
            bnds.min.longitude = min(bnds.min.longitude, t.bounds.min.longitude)
            bnds.max.latitude = max(bnds.max.latitude, t.bounds.max.latitude)
            bnds.max.longitude = max(bnds.max.longitude, t.bounds.max.longitude)
        }

        self.movingSeconds = seconds
        self.distanceKilometers = distance
        self.bounds = bnds
    }

    public var description: String {
        return "\(startTime) in \(timezoneInfo.tag), \(distanceKilometers) km in \(tracks.count) track(s)"
    }

    public func encodeToJson() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    static public func decodeFromJson(json: Data) throws -> Gps {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Gps.self, from: json)
    }
}
