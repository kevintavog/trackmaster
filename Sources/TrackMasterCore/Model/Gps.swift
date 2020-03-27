import Foundation

public class Gps: CustomStringConvertible {
    public let id: String
    public let path: String
    public let tracks: [GpsTrack]
    public let waypoints: [GpsWaypoint]
    public let timezoneInfo: TimezoneInfo
    public let startTime: Date
    public let endTime: Date
    public let kilometers: Double
    public let seconds: Double
    public let movingSeconds: Double
    public let bounds: Bounds

    public var countryNames: [String] = [String]()
    public var countryCodes: [String] = [String]()
    public var stateNames: [String] = [String]()
    public var cityNames: [String] = [String]()
    public var sites: [PlacenameSite] = [PlacenameSite]()


    static public func relativePath(_ base: String, _ file: URL) -> String {
        return file.path.deletingPathPrefix(base)
    }


    public init(path: String, 
            tracks: [GpsTrack],
            waypoints: [GpsWaypoint],
            tzInfo: TimezoneInfo) {
        self.path = path
        self.id = path.urlEscape()
        self.tracks = tracks
        self.waypoints = waypoints
        self.timezoneInfo = tzInfo
        let firstPoint = tracks.first!.segments.first!.points.first!
        let lastPoint = tracks.last!.segments.last!.points.last!
        self.startTime = firstPoint.time
        self.endTime = lastPoint.time
        self.seconds = firstPoint.seconds(between: lastPoint)

        var distance = 0.0
        var seconds = 0.0
        let bnds = Bounds()
        for t in tracks {
            distance += t.kilometers
            seconds += t.seconds
            bnds.min.latitude = min(bnds.min.latitude, t.bounds.min.latitude)
            bnds.min.longitude = min(bnds.min.longitude, t.bounds.min.longitude)
            bnds.max.latitude = max(bnds.max.latitude, t.bounds.max.latitude)
            bnds.max.longitude = max(bnds.max.longitude, t.bounds.max.longitude)
        }

        self.movingSeconds = seconds
        self.kilometers = distance
        self.bounds = bnds
    }

    public var description: String {
        return "\(startTime) in \(timezoneInfo.tag), \(kilometers) km in \(tracks.count) track(s)"
    }
}
