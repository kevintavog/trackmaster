import Foundation

public enum CalculatedStopType: String {
    case missingData, noMovement, poorData, groupedStops
}

public class CalculatedStop: GpsObject, CustomStringConvertible {
    public let stopType: CalculatedStopType
    public let beginLatitude: Double
    public let beginLongitude: Double
    public let beginTime: Date
    public let finishLatitude: Double
    public let finishLongitude: Double
    public let finishTime: Date

    static public func merge(_ stopType: CalculatedStopType, _ s1: CalculatedStop, _ s2: CalculatedStop) -> CalculatedStop {
        return CalculatedStop(
            stopType,
            min(s1.beginLatitude, s2.beginLatitude),
            min(s1.beginLongitude, s2.beginLongitude),
            min(s1.beginTime, s2.beginTime),
            max(s1.finishLatitude, s2.finishLatitude),
            max(s1.finishLongitude, s2.finishLongitude),
            max(s1.finishTime, s2.finishTime)
        )
    }

    public init(_ type: CalculatedStopType, _ beginLatitude: Double, _ beginLongitude: Double, _ beginTime: Date,
            _ finishLatitude: Double, _ finishLongitude: Double,_ finishTime: Date) {
        self.stopType = type
        self.beginLatitude = beginLatitude
        self.beginLongitude = beginLongitude
        self.beginTime = beginTime
        self.finishLatitude = finishLatitude
        self.finishLongitude = finishLongitude
        self.finishTime = finishTime
    }

    public var objectType: GpsObjectType { get { return .stop } }
    public var label: String { get { return "\(stopType)" } }


    public var description: String {
        return "\(Converter.shortTime(beginTime)) - \(Converter.shortTime(finishTime)); "
            + "\(Int(Converter.secondsBetween(beginTime, finishTime))) seconds; \(stopType)"
    }

    public func asWaypoint() -> GpsWaypoint {
        let wayPoint =  GpsWaypoint(
            (beginLatitude + finishLatitude) / 2,
            (beginLongitude + finishLongitude) / 2,
            0,
            beginTime,
            "\(stopType) from \(Converter.shortTime(beginTime)) - \(Converter.shortTime(finishTime))"
        )
        wayPoint.stop = self
        return wayPoint
    }

    public var seconds: Double {
        return Converter.secondsBetween(beginTime, finishTime)
    }

    public var distanceMeters: Double {
        return 1000 * Geo.distance(
                lat1: beginLatitude, lon1: beginLongitude,
                lat2: finishLatitude, lon2: finishLongitude)
    }

    public var speedMs: Double {
        return distanceMeters / seconds
    }
}
