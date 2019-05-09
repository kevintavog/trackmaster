import Foundation

func calculateChecksum(url: URL) throws -> String {
    return try MD5Invoker.md5(file: url.path)
}
