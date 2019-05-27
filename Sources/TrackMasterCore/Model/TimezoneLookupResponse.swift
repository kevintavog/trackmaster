import Foundation

public struct TimezoneInfo : Codable {
    public let id: String
    public let tag: String

    init(id: String, tag: String) {
        self.id = id
        self.tag = tag
    }

    static public func decodeFromJson(json: Data) throws -> TimezoneInfo {
        return try JSONDecoder().decode(TimezoneInfo.self, from: json)
    }
}
