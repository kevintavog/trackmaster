import Foundation


public class PointCalculator {
    private init() { }

    static public func process(_ tracks: [GpsTrack]) {
        for t in tracks {
            for s in t.segments {
                if s.points.count > 0 {
                    for idx in 0..<(s.points.count - 1) {
                        let cur = s.points[idx]
                        let next = s.points[idx + 1]

                        cur.calculatedCourse = Geo.bearing(pt1: cur, pt2: next)

                        cur.calculatedMeters = cur.distanceMeters(between: next)
                        cur.calculatedSeconds = cur.seconds(between: next)

                        // Under poor conditions, consecutive points can have the same timestamps
                        if cur.calculatedSeconds == 0.0 {
                            cur.calculatedSpeedMs = 0.0
                            cur.calculatedSpeedKmh = 0.0
                        } else {
                            cur.calculatedSpeedMs = cur.calculatedMeters / cur.calculatedSeconds
                            cur.calculatedSpeedKmh = Converter.metersPerSecondToKilometersPerHour(metersSecond: cur.calculatedSpeedMs)
                        }

                        cur.transportationTypes = Transportation.calculate(pt: cur)
                    }
                }
            }
        }
    }
}
