import Foundation


public func enumerateFiles(_ path: URL) throws -> [URL] {
    let enumerator = FileManager.default.enumerator(
        at: path,
        includingPropertiesForKeys: [],
        options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
            print("enumerateFiles error at \(url): \(error)")
            return true
        }
    )!

    var files = [URL]()
    for case let fileURL as URL in enumerator {
        print("  Checking \(fileURL.path) [\(fileURL.hasDirectoryPath)]")
        if !fileURL.hasDirectoryPath {
            files.append(fileURL)
        }
    }

    return files
}
