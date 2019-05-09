import Foundation

public var ReverseNameLookupServer = ""

public func reverseNameLookup(lat: Double, lon: Double, distance: Int) -> ReverseNameLookupResponse? {
    if ReverseNameLookupServer == "" {
        print("Skipping reverse name lookup, the server is not set")
        return nil
    }
    do {
        let response = try httpGetJson(
            host: ReverseNameLookupServer,
            path: "/api/v1/cached-name",
            parameters: ["lat": String(lat), "lon": String(lon), "distance": String(distance), "country": String(true)])
        let rnl = try ReverseNameLookupResponse.decodeFromJson(json: response!.rawData())
        if rnl.description != "" {
            return rnl
        }
    } catch {
        // Ignore, it doesn't matter
print("rnl failed: \(error)")
    }
    return nil
}
