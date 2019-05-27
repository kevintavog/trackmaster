import Foundation

public struct Track: Codable {
    public let id: String
    public let path: String
    public let checksum: String
    public var timezoneInfo: TimezoneInfo
    public var startTime: Date
    public var endTime: Date
    public let indexTime: Date
    public var bounds: Bounds
    public var countryNames: [String]? = [String]()
    public var countryCodes: [String]? = [String]()
    public var stateNames: [String]? = [String]()
    public var cityNames: [String]? = [String]()
    public var siteNames: [String]? = [String]()


    public init(path: String, checksum: String, timezoneInfo: TimezoneInfo, 
            startTime: Date, endTime: Date, bounds: Bounds) {
        self.id = path.urlEscape()
        self.path = path
        self.checksum = checksum
        self.timezoneInfo = timezoneInfo
        self.startTime = startTime
        self.endTime = endTime
        self.bounds = bounds
        self.indexTime = Date()
    }

    public func encodeToJson() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    static public func decodeFromJson(json: Data) throws -> Track {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Track.self, from: json)
    }
}
