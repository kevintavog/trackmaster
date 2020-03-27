import Foundation

public struct ReverseNameLookupResponse : Codable {
    let description: String
    let fullDescription: String
    let sites: [String]?
    let city: String?
    let state: String?
    let countryCode: String?
    let countryName: String?
    let latitude: Double?
    let longitude: Double?

    static public func decodeFromJson(json: Data) throws -> ReverseNameLookupResponse {
        return try JSONDecoder().decode(ReverseNameLookupResponse.self, from: json)
    }
}
