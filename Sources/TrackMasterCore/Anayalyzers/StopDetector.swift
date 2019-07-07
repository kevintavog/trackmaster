import Foundation

// Responsible for filtering out sequences of points that are likely stops
// From https://medium.com/strava-engineering/the-global-heatmap-now-6x-hotter-23fc01d301de
//  Referenced from https://gis.stackexchange.com/questions/89451/how-to-calculate-stop-points-from-a-set-of-gps-tracklogs
// If the magnitude of the time averaged velocity of an activity stream gets too low 
// at any point, subsequent points from that activity are movingPoints until the activity
// breaches a specific radius in distance from the initial stopped point.
public class StopDetector {
    static fileprivate let tooSlowAverageKmH = 0.3
    static fileprivate let ignoreRadiusKm = 0.003

    static fileprivate let averageSeconds = 15.0
    fileprivate var movingAverage = [GpsPoint]()

    public var movingPoints = [GpsPoint]()
    public var stops = [GpsStop]()
    public var clusters = [ClusterStop]()

    public init() {
    }

    public func analyze(points: [GpsPoint]) -> StopDetector {
        self.movingPoints = filter(points)
        return self
    }

    fileprivate func filter(_ points: [GpsPoint]) -> [GpsPoint] {
        var movingPoints = [GpsPoint]()
        var discardRadiusPoint: GpsPoint? = nil
        var discardPoints = [GpsPoint]()

        for pt in points {
            // Get rid of points that are too fast, they skew results
            if pt.problems.contains(PointProblem.tooFast) {
print("Throwing out too fast point: \(pt.time) - \(pt.calculatedSpeedKmHFromPrevious)")
                continue
            }

            // If we're discarding points due to lack of movement, continue until
            // we get far enough away.
            if let radiusPoint = discardRadiusPoint {
                if radiusPoint.distanceKm(between: pt) < StopDetector.ignoreRadiusKm {
                    discardPoints.append(pt)
                    continue
                }

                if discardPoints.count > 0 {
                    stops.append(GpsStop(points: discardPoints))
                }

                discardRadiusPoint = nil
                discardPoints.removeAll(keepingCapacity: true)
            }

            let average = updateAverage(pt)
            pt.movingAverageKmH = average

            // If our average speed drops, discard points until the stop radius is exceeded
            if pt.movingAverageKmH < StopDetector.tooSlowAverageKmH {
                discardRadiusPoint = pt
                discardPoints.append(pt)
                continue
            }

            if movingPoints.count > 0 {
                PointChanges.analyze(prev: movingPoints.last, point: pt)
            } else {
                PointChanges.clear(point: pt)
            }
            movingPoints.append(pt)
        }

        // Combine stops near each other
        var combinedStops = [GpsStop]()
        if stops.count > 0 {
            combinedStops.append(stops[0])

            for idx in 1..<stops.count {
                let prev = combinedStops.last!
                let cur = stops[idx]
                let distance = cur.firstPoint.distanceMeters(between: prev.lastPoint)
                let seconds = prev.lastPoint.seconds(between: cur.firstPoint)
                if distance < 5 && seconds < 5 {
                    combinedStops.last!.extend(stop: cur)
                } else {
// print("\(cur.startTime); \(distance) meters; \(seconds) seconds from previous")
                    combinedStops.append(cur)
                }
            }
        }
        stops = combinedStops
        return movingPoints.filter { !inStop($0) }
    }

    fileprivate func inStop(_ point: GpsPoint) -> Bool {
        for s in stops {
            if s.contains(point: point) {
                return true
            }
        }
        return false
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


    fileprivate func findStopIndex(_ pt: GpsPoint) -> Int {
        return stops.firstIndex(where: { $0.startTime == pt.time }) ?? -1
    }
}
