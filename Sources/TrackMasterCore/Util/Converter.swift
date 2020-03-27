import Foundation

public struct Converter {
    static private var _dateTimeFormatter: DateFormatter?
    static public var dateTimeFormatter: DateFormatter {
        get {
            if _dateTimeFormatter == nil {
                let dt = DateFormatter()
                dt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                dt.timeZone = TimeZone(secondsFromGMT: 0)
                _dateTimeFormatter = dt
            }
            return _dateTimeFormatter!
        }
    }


    static public func fullDateString(_ time: Date) -> String {
        return dateTimeFormatter.string(from: time)
    }

    static public func shortTime(_ time: Date) -> String {
        return String(fullDateString(time).suffix(9).prefix(8))
    }

    // Number of seconds between two dates, independent of which is earlier
    static public func secondsBetween(_ a: Date, _ b: Date) -> Double {
        return abs(a.timeIntervalSince(b))
    }

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
