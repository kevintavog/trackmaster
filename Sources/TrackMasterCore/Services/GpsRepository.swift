import Foundation

public class GpsRepository {
    static public var gpsFolder: String? = nil

    static public func save(gps: Gps) throws {
        let path = gps.path.replacingOccurrences(of: ".gpx", with: ".json")
        let fileUrl = URL(fileURLWithPath: "\(gpsFolder!)\(path)")
        try FileManager.default.createDirectory(
            at: fileUrl.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        let data = try gps.encodeToJson()
        try data.write(to: fileUrl, options: [.atomic])
    }

    static public func loadRaw(path: String) throws -> String {
        let gpsPath = path.replacingOccurrences(of: ".gpx", with: ".json")
        let fileData = try Data(contentsOf: URL(fileURLWithPath: "\(gpsFolder!)\(gpsPath)"))
        return String(data: fileData, encoding: .utf8)!
    }
}
