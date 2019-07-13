import Foundation

// Responsible for calculating changes between consecutive point.
public class PointChanges {
    static let minKmH = 0.3
    static let maxKmH = 350.0

    static public func analyze(prev: GpsPoint?, point: GpsPoint) {
        if let validPrev = prev {
            point.kmFromPrevious = validPrev.distanceKm(between: point)
            point.secondsFromPrevious = validPrev.seconds(between: point)
            point.calculatedSpeedKmHFromPrevious = validPrev.speedKmh(between: point)
            point.calculatedCourseFromPrevious = Geo.bearing(pt1: validPrev, pt2: point)
            point.transportationTypes = Transportation.calculate(speedKmh: point.calculatedSpeedKmHFromPrevious)

            if point.calculatedSpeedKmHFromPrevious < minKmH {
                point.problems.append(PointProblem.noSpeed)
            } else {
                if point.calculatedSpeedKmHFromPrevious > maxKmH {
                    point.problems.append(PointProblem.tooFast)
                }
            }
        }
    }

    static public func clear(point: GpsPoint) {
        point.kmFromPrevious = 0.0
        point.secondsFromPrevious = 0.0
        point.calculatedSpeedKmHFromPrevious = 0.0
        point.calculatedCourseFromPrevious = 0
    }
}
