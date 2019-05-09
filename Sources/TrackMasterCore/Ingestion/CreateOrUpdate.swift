import Foundation

public func ShouldCreateOrUpdate(_ base: String, _ inputFile: URL) throws -> Bool {
    let id = inputFile.path.deletingPathPrefix(base).urlEscape()
    if let track = try ElasticSearchClient.get(id: id) {
        let checksum = try calculateChecksum(url: inputFile)
        return track.checksum != checksum
    }
    return true
}
