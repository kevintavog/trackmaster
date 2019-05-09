import Foundation

public class MD5Invoker {
    enum Error : Swift.Error {
        case runFailed(error: String)
        case failedParsingOutput(error: String)
    }

    static func md5(file: String) throws -> String {
        let output = try runMD5([ "-r"] + [file])

        var lines = [String]()
        output.enumerateLines { line, _ in
            lines.append(line)
        }
        if lines.count == 1 {
            if let index = lines[0].range(of: " ") {
                return String(lines[0][..<index.lowerBound])
            }
        }
        throw Error.failedParsingOutput(error: output)
    }

    static var md5Path: String { return "/sbin/md5" }

    static fileprivate func runMD5(_ arguments: [String]) throws -> String {
        let process = ProcessInvoker.run(md5Path, arguments: arguments)
        if process.exitCode == 0 {
            return process.output
        }

        throw Error.runFailed(error: "md5 failed: exit code: \(process.exitCode); error: '\(process.error)'; \(arguments)")
    }
}
