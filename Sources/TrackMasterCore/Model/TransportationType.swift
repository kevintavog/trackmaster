import Foundation

public enum TransportationMode: String, Codable {
    case unknown = "unknown"
    case foot = "foot"
    case bicycle = "bicycle"
    case car = "car"
    case train = "train"
    case plane = "plane"
}

public struct TransportationType: Codable {
    public let probability: Double
    public let mode: TransportationMode

    init(probability: Double, mode: TransportationMode) {
        self.probability = probability
        self.mode = mode
    }
}
