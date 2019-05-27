import TrackMasterCore
import Vapor

public struct ControllerTrack: Codable, Content {
    public let id: String
    public let path: String
    public let checksum: String
    public let timezoneInfo: TimezoneInfo
    public let startTime: Date?
    public let endTime: Date?
    public let indexTime: Date?
    public let bounds: Bounds
    public let countryNames: [String]
    public let countryCodes: [String]
    public let stateNames: [String]
    public let cityNames: [String]
    public let siteNames: [String]


    public init(track: Track) {
        self.id = track.id
        self.path = track.path
        self.checksum = track.checksum
        self.timezoneInfo = track.timezoneInfo
        self.startTime = track.startTime
        self.endTime = track.endTime
        self.indexTime = track.indexTime
        self.bounds = track.bounds
        self.countryNames = ControllerTrack.namesByCount(track.countryNames)
        self.countryCodes = ControllerTrack.namesByCount(track.countryCodes)
        self.stateNames = ControllerTrack.namesByCount(track.stateNames)
        self.cityNames = ControllerTrack.namesByCount(track.cityNames)
        self.siteNames = ControllerTrack.namesByCount(track.siteNames)
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