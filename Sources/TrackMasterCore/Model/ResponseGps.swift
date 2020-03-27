import Foundation

public struct PlacenameSite: Codable {
    public let names: [String]
    let latitude: Double?
    let longitude: Double?

    public init(names: [String], latitude: Double?, longitude: Double?) {
        self.names = names
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct ResponseGps: Codable {
    public let id: String
    public let path: String
    public let checksum: String
    public var timezoneInfo: TimezoneInfo
    public var startTime: Date
    public var endTime: Date
    public let indexTime: Date
    public var bounds: Bounds
    public let seconds: Double?
    public let movingSeconds: Double?
    public let kilometers: Double?
    public var countryNames: [String]? = [String]()
    public var countryCodes: [String]? = [String]()
    public var stateNames: [String]? = [String]()
    public var cityNames: [String]? = [String]()
    public var sites: [PlacenameSite] = [PlacenameSite]()

    public init(gps: Gps, checksum: String) {
        self.id = gps.id
        self.path = gps.path
        self.checksum = checksum
        self.timezoneInfo = gps.timezoneInfo
        self.startTime = gps.startTime
        self.endTime = gps.endTime
        self.bounds = gps.bounds
        self.seconds = gps.seconds
        self.movingSeconds = gps.movingSeconds
        self.kilometers = gps.kilometers
        self.indexTime = Date()

        self.countryNames = gps.countryNames
        self.countryCodes = gps.countryCodes
        self.stateNames = gps.stateNames
        self.cityNames = gps.cityNames
        self.sites = gps.sites
    }

    public init(path: String, checksum: String, timezoneInfo: TimezoneInfo, 
            startTime: Date, endTime: Date, bounds: Bounds,
            seconds: Double, movingSeconds: Double, kilometers: Double) {
        self.id = path.urlEscape()
        self.path = path
        self.checksum = checksum
        self.timezoneInfo = timezoneInfo
        self.startTime = startTime
        self.endTime = endTime
        self.bounds = bounds
        self.seconds = seconds
        self.movingSeconds = movingSeconds
        self.kilometers = kilometers
        self.indexTime = Date()
    }

    public func encodeToJson() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    static public func decodeFromJson(json: Data) throws -> ResponseGps {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ResponseGps.self, from: json)
    }
}
