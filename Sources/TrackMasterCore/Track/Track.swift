import Foundation

public struct Track: Codable {
    public let id: String
    public let path: String
    public let checksum: String
    public var startTime: Date?
    public var endTime: Date?
    public let indexTime: Date?
    public var bounds = Track.Bounds()
    public var countryNames: [String]? = [String]()
    public var countryCodes: [String]? = [String]()
    public var stateNames: [String]? = [String]()
    public var cityNames: [String]? = [String]()
    public var siteNames: [String]? = [String]()


    public init(path: String, checksum: String) {
        self.id = path.urlEscape()
        self.path = path
        self.checksum = checksum
        self.indexTime = Date()
    }

    public struct Bounds: Codable {
        public var min = Point()
        public var max = Point()
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
