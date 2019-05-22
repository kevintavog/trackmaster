import Foundation

public enum TMError: Error {
    case httpError(status: UInt, message: String)
    case elasticSearchError(status: UInt, type: String, reason: String)
    case invalidParameter(message: String)
    case unexpected(message: String)
    case notFound(message: String)
}
