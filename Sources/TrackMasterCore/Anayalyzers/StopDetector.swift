import Foundation

// Responsible for filtering out sequences of points that are likely stops
// From https://medium.com/strava-engineering/the-global-heatmap-now-6x-hotter-23fc01d301de
//  Referenced from https://gis.stackexchange.com/questions/89451/how-to-calculate-stop-points-from-a-set-of-gps-tracklogs
// If the magnitude of the time averaged velocity of an activity stream gets too low 
// at any point, subsequent points from that activity are filtered until the activity
// breaches a specific radius in distance from the initial stopped point.
public class StopDetector {
    // fileprivate let tooSlowAverageKmH = 0.4
    static fileprivate let tooSlowAverageKmH = 0.30
    static fileprivate let ignoreRadiusKm = 0.009

    static fileprivate let minRunSeconds = 20.0
    static fileprivate let minRunDistanceKm = 20.0 / 1000.0    // (meters => kilometers)

    static fileprivate let averageSeconds = 10.0
    fileprivate var movingAverage = [GpsPoint]()

    public var movingPoints = [GpsPoint]()
    public var stopPoints = [GpsPoint]()
    public var removedRuns = [GpsRun]()

    public init() {
    }

    public func analyze(points: [GpsPoint]) -> StopDetector {
        self.movingPoints = filter(points)
        return self
    }

/*
    static public func filterStops(start: Date, end: Date) -> [GpsPoint] {
        return stopPoints.filter { $0.time >= start && $0.time <= end}
    }

    static public func filterRuns(start: Date, end: Date) -> [GpsRun] {
        return removedRuns.filter { $0.points.first!.time >= start && $0.points.last!.time <= end}
    }

    static public func overlapStops(points: [GpsPoint]) -> Int {
        var count = 0
        for pt in points {
            stopRects.forEach { count += $0.within(point: pt ) ? 1 : 0}
        }
        return count
    }

    static public func emitOverlapping(runs: [GpsRun]) {
        emitOverlapping(stops: stopPoints, runs: runs)
    }

    static public func emitOverlapping(stops: [GpsPoint], runs: [GpsRun]) {
        var runIndex = 0
        var stopIndex = 0
        let prevPoint = GeoPointInstance(point: stops[0])
        var prevTime = stops[0].time
        while (runIndex < runs.count && stopIndex < stops.count) {
            let r = runs[runIndex]
            let s = stops[stopIndex]
            if r.points.first!.time < s.time {
                let movement = Int(1000 * r.points.first!.distanceKm(between: r.points.last!))
                let meters = Int(Geo.distance(pt1: r.points.last!, pt2: prevPoint) * 1000)
                let last = "\(abs(r.points.first!.time.timeIntervalSince(prevTime))) seconds, \(meters) meters"
                print("run: \(r.seconds) seconds, \(Int(1000 * r.kilometers)) meters @\(r.points.first!.time) / \(movement), \(last)")
                runIndex += 1

                prevPoint.latitude = r.points.last!.latitude
                prevPoint.longitude = r.points.last!.longitude
                prevTime = r.points.last!.time
            } else {
                let meters = Int(Geo.distance(pt1: s, pt2: prevPoint) * 1000)
                let last = "\(abs(s.time.timeIntervalSince(prevTime))) seconds, \(meters) meters"
                print("stop: @\(s.time), \(last)")

                prevPoint.latitude = s.latitude
                prevPoint.longitude = s.longitude
                prevTime = s.time
                stopIndex += 1
            }
        }
    }

    static public func emit() {
        var prev: GpsPoint? = nil
        for pt in stopPoints {
            var extra = ""
            if let r = prev {
                let distance = r.distanceKm(between: pt)
                let seconds = r.seconds(between: pt)
                extra = ", \(Int(distance * 1000)) meters and \(seconds) from previous"
            }
            print("\(pt)\(extra)")
            prev = pt
        }
    }

    static public func analyze(points: [GpsPoint]) -> [GpsPoint] {
        return StopFilter().filter(points)
    }
*/
/*
    static public func analyze(runs: [GpsRun]) -> [GpsRun] {
        var firstPass = [GpsRun]()
        for r in runs {
            if r.seconds > minRunSeconds && r.kilometers > minRunDistanceKm {
                firstPass.append(r)
            } else {
                removedRuns.append(r)
            }
        }

        return firstPass
    }
*/
    fileprivate func filter(_ points: [GpsPoint]) -> [GpsPoint] {
        var filtered = [GpsPoint]()
        var discardRadiusPoint: GpsPoint? = nil
        var discardPoints = [GpsPoint]()

        for pt in points {
            // Get rid of points that are too fast, they skew results
            if pt.problems.contains(PointProblem.tooFast) {
                continue
            }

            // If we're discarding points due to lack of movement, continue until
            // we get far enough away.
            if let radiusPoint = discardRadiusPoint {
                if radiusPoint.distanceKm(between: pt) < StopDetector.ignoreRadiusKm {
                    discardPoints.append(pt)
                    continue
                }

                discardRadiusPoint = nil
                discardPoints.removeAll(keepingCapacity: true)
            }

            let average = updateAverage(pt)
            pt.movingAverageKmH = average

            // Once our average speed drops, discard points until the stop radius is exceeded
            if pt.movingAverageKmH < StopDetector.tooSlowAverageKmH {
                discardRadiusPoint = pt
                stopPoints.append(pt)
                while let last = filtered.last {
                    if pt.distanceKm(between: last) < StopDetector.ignoreRadiusKm 
                            || last.movingAverageKmH < StopDetector.tooSlowAverageKmH {
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
        while pt.seconds(between: movingAverage[0]) > StopDetector.averageSeconds {
            movingAverage.remove(at: 0)
        }

        var totalKmh = 0.0
        for point in movingAverage {
            totalKmh += point.calculatedSpeedKmHFromPrevious
        }
        return totalKmh / Double(movingAverage.count)
    }
}
