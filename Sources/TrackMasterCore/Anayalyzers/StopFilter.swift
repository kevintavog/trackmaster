import Foundation

// Responsible for filtering out sequences of points that are likely stops
// From https://medium.com/strava-engineering/the-global-heatmap-now-6x-hotter-23fc01d301de
//  Referenced from https://gis.stackexchange.com/questions/89451/how-to-calculate-stop-points-from-a-set-of-gps-tracklogs
// If the magnitude of the time averaged velocity of an activity stream gets too low 
// at any point, subsequent points from that activity are filtered until the activity
// breaches a specific radius in distance from the initial stopped point.
public class StopFilter {
    // fileprivate let tooSlowAverageKmH = 0.4
    fileprivate let tooSlowAverageKmH = 0.30
    fileprivate let ignoreRadiusKm = 0.009

    static fileprivate let minRunSeconds = 20.0
    static fileprivate let minRunDistanceKm = 20.0 / 1000.0    // (meters => kilometers)

    fileprivate let averageSeconds = 10.0
    fileprivate var movingAverage = [GpsPoint]()

    static public var stopPoints = [GpsPoint]()
    static public var removedRuns = [GpsRun]()

    static public func filterStops(start: Date, end: Date) -> [GpsPoint] {
        return stopPoints.filter { $0.time >= start && $0.time <= end}
    }

    static public func filterRuns(start: Date, end: Date) -> [GpsRun] {
        return removedRuns.filter { $0.points.first!.time >= start && $0.points.last!.time <= end}
    }

    static public func emit() {
        var prev: GpsPoint? = nil
        for pt in stopPoints {
            var extra = ""
            if let r = prev {
                let distance = r.distanceKm(between: pt)
                extra = ", \(Int(distance * 1000)) meters from previous"
            }
            print("\(pt)\(extra)")
            prev = pt
        }
    }

    static public func analyze(points: [GpsPoint]) -> [GpsPoint] {
        return StopFilter().filter(points)
    }

    static public func analyze(runs: [GpsRun]) -> [GpsRun] {
        var firstPass = [GpsRun]()
        var prevRun: GpsRun? = nil
        for r in runs {
            if r.seconds > minRunSeconds && r.kilometers > minRunDistanceKm {
                firstPass.append(r)
            } else {
                removedRuns.append(r)
            }
        }

        var filtered = [GpsRun]()
        for r in firstPass {
            var stopsCount = 0
            var removedRunsCount = 0
            if let pr = prevRun {
                stopsCount = filterStops(start: pr.points.last!.time, end: r.points.first!.time).count
                removedRunsCount = filterRuns(start: pr.points.last!.time, end: r.points.first!.time).count
// print("\(r.points.first!.time): \(stopsCount); \(removedRunsCount)")
            }

            prevRun = r
            if (stopsCount + removedRunsCount) < 3 {
                filtered.append(r)
            }
        }

        return filtered
    }

    fileprivate init() { }


    fileprivate func filter(_ points: [GpsPoint]) -> [GpsPoint] {
        var filtered = [GpsPoint]()
        var discardRadiusPoint: GpsPoint? = nil
        var discardPoints = [GpsPoint]()

        for pt in points {
            // Get rid of points that are too fast, they skew results
            if pt.problems.contains(PointProblem.tooFast) {
                continue
            }

            if let radiusPoint = discardRadiusPoint {
                if radiusPoint.distanceKm(between: pt) < ignoreRadiusKm {
                    discardPoints.append(pt)
                    continue
                }

// if discardPoints.count > 1 {
//     print("Removing \(discardPoints.count) from \(discardPoints.first!.time), " +
//         "\(discardPoints.first!.seconds(between: discardPoints.last!)) seconds and " +
//         "\(Int( 1000 * discardPoints.first!.distanceKm(between: discardPoints.last!))) meters")
// }

                discardRadiusPoint = nil
                discardPoints.removeAll(keepingCapacity: true)
            }

            let average = updateAverage(pt)
            pt.movingAverageKmH = average

            // Once our average speed drops, discard points until the stop radius is exceeded
            if pt.movingAverageKmH < tooSlowAverageKmH {
                discardRadiusPoint = pt
                StopFilter.stopPoints.append(pt)
                while let last = filtered.last {
                    if pt.distanceKm(between: last) < ignoreRadiusKm || last.movingAverageKmH < tooSlowAverageKmH {
                        discardPoints.insert(last, at: 0)
                        filtered.removeLast()
                    } else {
                        break
                    }
                }
                discardPoints.append(pt)
                continue
            }

            var keep = true
            if pt.movingAverageKmH > (pt.calculatedSpeedKmHFromPrevious * 3) ||
                    pt.movingAverageKmH < (pt.calculatedSpeedKmHFromPrevious / 3) {
// print("Tossing \(pt.time); \(pt.calculatedSpeedKmHFromPrevious) ~= \(pt.movingAverageKmH) ~= \(pt.speedKmH)")
                keep = false
                movingAverage.removeLast()
            }

            if keep {
                if filtered.count > 0 {
                    PointChanges.analyze(prev: filtered.last, point: pt)
                } else {
                    PointChanges.clear(point: pt)
                }
                filtered.append(pt)
            }
        }
        return filtered
    }

    fileprivate func updateAverage(_ pt: GpsPoint) -> Double {
        movingAverage.append(pt)
        while pt.seconds(between: movingAverage[0]) > averageSeconds {
            movingAverage.remove(at: 0)
        }

        var totalKmh = 0.0
        for point in movingAverage {
            totalKmh += point.calculatedSpeedKmHFromPrevious
        }
        return totalKmh / Double(movingAverage.count)
    }
}
