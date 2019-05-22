import TrackMasterCore
import Vapor

public struct ControllerTrack: Codable, Content {
    public let id: String
    public let path: String
    public let checksum: String
    public let startTime: Date?
    public let endTime: Date?
    public let indexTime: Date?
    public let bounds: Track.Bounds
    public let countryNames: [String]
    public let countryCodes: [String]
    public let stateNames: [String]
    public let cityNames: [String]
    public let siteNames: [String]

    public let flatCountries: String
    public let flatStates: String
    public let flatCities: String
    public let flatSites: String


    public init(track: Track) {
        self.id = track.id
        self.path = track.path
        self.checksum = track.checksum
        self.startTime = track.startTime
        self.endTime = track.endTime
        self.indexTime = track.indexTime
        self.bounds = track.bounds
        self.countryNames = track.countryNames ?? [String]()
        self.countryCodes = track.countryCodes ?? [String]()
        self.stateNames = track.stateNames ?? [String]()
        self.cityNames = track.cityNames ?? [String]()
        self.siteNames = track.siteNames ?? [String]()

        self.flatCountries = ControllerTrack.unique(self.countryNames)
        self.flatStates = ControllerTrack.unique(self.stateNames)
        self.flatCities = ControllerTrack.unique(self.cityNames)
        self.flatSites = ControllerTrack.unique(self.siteNames)
    }

    static private func unique(_ list: [String]) -> String {
        if list.count > 0 {
            var seen = Set<String>()
            return list.filter { seen.insert($0).inserted }.joined(separator: ", ")
        }
        return ""

    }
}