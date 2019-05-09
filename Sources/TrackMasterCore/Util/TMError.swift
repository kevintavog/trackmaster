import Foundation

public enum TMError: Error {
    case httpError(status: UInt, message: String)
}
