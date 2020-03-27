import SwiftyXML

extension Bounds {
    public func toXML() -> XML {
        return XML(
            name: "bounds",
            attributes: [
                "minLat": min.latitude,
                "minLon": min.longitude,
                "maxLat": max.latitude,
                "maxLon": max.longitude
            ])
    }
}
