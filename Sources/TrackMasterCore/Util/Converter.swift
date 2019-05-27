import Foundation

public struct Converter {
    static public func metersPerSecondToKilometersPerHour(metersSecond: Double) -> Double {
        return metersSecond * (3600.0 / 1000.0)
    }

    static public func kilometersPerHourToMetersPerSecond(kmh: Double) -> Double {
        return kmh * (1000.0 / 3600.0)
    }

    static public func speedKph(seconds: Double, kilometers: Double) -> Double {
        let time = (seconds / 3600.0)
        if time < 0.000001 {
            return 0.0
        }
        return kilometers / time
    }

    static public func speedKph(seconds: Int, kilometers: Double) -> Double {
        return Converter.speedKph(seconds: Double(seconds), kilometers: kilometers)
    }

    static public func speedKph(seconds: Double, meters: Double) -> Double {
        return Converter.speedKph(seconds: seconds, kilometers: meters * 1000.0)
    }
}
