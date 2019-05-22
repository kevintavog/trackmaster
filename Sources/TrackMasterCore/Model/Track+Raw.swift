import Foundation

extension Track {
    public func raw() throws -> String {
        let fileData = try Data(contentsOf: URL(fileURLWithPath: BaseTrackFolder + self.path))
        return String(data: fileData, encoding: .utf8)!
    }
}
