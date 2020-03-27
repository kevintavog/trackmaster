import TrackMasterCore
import Vapor

public struct ControllerTrack: Codable, Content {
    public let id: String
    public let path: String
    public let checksum: String
    public let timezoneInfo: TimezoneInfo
    public let startTime: Date?
    public let endTime: Date?
    public let seconds: Double?
    public let movingSeconds: Double?
    public let kilometers: Double?
    public let indexTime: Date?
    public let bounds: Bounds
    public let countryNames: [String]
    public let countryCodes: [String]
    public let stateNames: [String]
    public let cityNames: [String]
    public let sites: [PlacenameSite]


    public init(gps: ResponseGps) {
        self.id = gps.id
        self.path = gps.path
        self.checksum = gps.checksum
        self.timezoneInfo = gps.timezoneInfo
        self.startTime = gps.startTime
        self.endTime = gps.endTime
        self.seconds = gps.seconds
        self.movingSeconds = gps.movingSeconds
        self.kilometers = gps.kilometers
        self.indexTime = gps.indexTime
        self.bounds = gps.bounds
        self.countryNames = ControllerTrack.namesByCount(gps.countryNames)
        self.countryCodes = ControllerTrack.namesByCount(gps.countryCodes)
        self.stateNames = ControllerTrack.namesByCount(gps.stateNames)
        self.cityNames = ControllerTrack.namesByCount(gps.cityNames)
        self.sites = gps.sites
    }

    // Given an array of string names with likely duplicates, return the
    // unique names, orderd by count
    static fileprivate func namesByCount(_ list: [String]!) -> [String] {
        if list != nil && list!.count > 0 {
            var dict = [String:Int]()
            list!.forEach { dict[$0, default: 0] += 1 }
            return dict.keys.sorted(by: { dict[$0]! > dict[$1]! })
        }
        return [""]
    }
}