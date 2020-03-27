import SwiftyXML

extension TransportationType {
    // Assumed to be added as a child to `extensions`
    public func toXML() -> XML {
        return XML(name: "transportationType", attributes: ["probability": probability, "mode": mode])
    }
}
