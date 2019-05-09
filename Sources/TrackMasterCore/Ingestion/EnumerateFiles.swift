import Foundation


public func enumerateFiles(_ path: URL) throws -> [URL] {
    let resourceKeys : [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
    let enumerator = FileManager.default.enumerator(
        at: path,
        includingPropertiesForKeys: resourceKeys,
        options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
            print("enumerateFiles error at \(url): \(error)")
            return true
        }
    )!

    var files = [URL]()
    for case let fileURL as URL in enumerator {
        let resValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
        if !resValues.isDirectory! {
            files.append(fileURL)
        }
    }

    return files
}
