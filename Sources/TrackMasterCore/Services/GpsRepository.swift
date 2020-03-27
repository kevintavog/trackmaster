import Foundation

public class GpsRepository {
    static public var analyzedFolder: String? = nil
    static public var originalFolder: String? = nil

    static public func save(gps: Gps) throws {
        let fileUrl = URL(fileURLWithPath: "\(analyzedFolder!)\(gps.path)")
        try FileManager.default.createDirectory(
            at: fileUrl.deletingLastPathComponent(),
            withIntermediateDirectories: true)

        let xml = gps.toXML()
        try xml.toXMLString().write(to: fileUrl, atomically: true, encoding: .utf8)
    }

    static public func loadRaw(path: String) throws -> String {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: "\(analyzedFolder!)\(path)"))
        return String(data: fileData, encoding: .utf8)!
    }

    static public func loadOriginal(path: String) throws -> String {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: "\(originalFolder!)\(path)"))
        return String(data: fileData, encoding: .utf8)!
    }
}
