import Foundation

extension String {
    public func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    public func deletingPathPrefix(_ prefix: String) -> String {
        let relative = self.deletingPrefix(prefix)
        if relative.prefix(1) != "/" {
            return "/" + relative
        }
        return relative
    }

    public func urlEscape() -> String {
        return self.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
    }

    public func subString(_ start: Int, _ end: Int) -> String {
        let firstIndex = index(startIndex, offsetBy: start)
        let lastIndex = index(startIndex, offsetBy: end)
        return String(self[firstIndex...lastIndex])
    }
}
