import Foundation
import TrackMasterCore
import Vapor

public struct ControllerError: Error, Debuggable {
    public let identifier: String
    public let reason: String

    public init(id: String, reason: String) {
        self.identifier = id
        self.reason = reason
    }

    public init(error: Error) {
        if let tmError = error as? TMError {
            switch tmError {
                case .httpError(let status, let message):
                    self.identifier = "http"
                    self.reason = "\(status): \(message)"
                case .elasticSearchError(let status, let type, let reason):
                    self.identifier = "elasticSearch"
                    self.reason = "\(status): \(type); \(reason)"
                case .invalidParameter(let message):
                    self.identifier = "invalidParameter"
                    self.reason = message
                case .unexpected(let message):
                    self.identifier = "unexpected"
                    self.reason = message
                case .notFound(let message):
                    self.identifier = "notFound"
                    self.reason = message
            }
        } else {
            self.identifier = "error"
            self.reason = "\(error)"
        }        
    }
}
