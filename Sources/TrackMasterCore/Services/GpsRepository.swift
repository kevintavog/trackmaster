import Foundation

public class GpsRepository {
    static public var analyzedFolder: String? = nil
    static public var originalFolder: String? = nil

    static public func save(gps: Gps) throws {
        let path = gps.path.replacingOccurrences(of: ".gpx", with: ".json")
        let fileUrl = URL(fileURLWithPath: "\(analyzedFolder!)\(path)")
        try FileManager.default.createDirectory(
            at: fileUrl.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        let data = try gps.encodeToJson()
        try data.write(to: fileUrl, options: [.atomic])
    }

    static public func loadRaw(path: String) throws -> String {
        let gpsPath = path.replacingOccurrences(of: ".gpx", with: ".json")
        let fileData = try Data(contentsOf: URL(fileURLWithPath: "\(analyzedFolder!)\(gpsPath)"))
        return String(data: fileData, encoding: .utf8)!
    }

    static public func loadOriginal(path: String) throws -> String {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: "\(originalFolder!)\(path)"))
        return String(data: fileData, encoding: .utf8)!
    }
}
