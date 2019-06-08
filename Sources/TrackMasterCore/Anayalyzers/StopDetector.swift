import Foundation

// Responsible for filtering out sequences of points that are likely stops
// From https://medium.com/strava-engineering/the-global-heatmap-now-6x-hotter-23fc01d301de
//  Referenced from https://gis.stackexchange.com/questions/89451/how-to-calculate-stop-points-from-a-set-of-gps-tracklogs
// If the magnitude of the time averaged velocity of an activity stream gets too low 
// at any point, subsequent points from that activity are movingPoints until the activity
// breaches a specific radius in distance from the initial stopped point.
public class StopDetector {
    // fileprivate let tooSlowAverageKmH = 0.4
    static fileprivate let tooSlowAverageKmH = 0.30
    static fileprivate let ignoreRadiusKm = 0.005

    static fileprivate let minRunSeconds = 20.0
    static fileprivate let minRunDistanceKm = 20.0 / 1000.0    // (meters => kilometers)

    static fileprivate let maxClusterSeconds = 60.0
    static fileprivate let maxClusterMeters = 60


    static fileprivate let averageSeconds = 10.0
    fileprivate var movingAverage = [GpsPoint]()

    public var movingPoints = [GpsPoint]()
    public var stopPoints = [GpsPoint]()
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
                continue
            }

            // If we're discarding points due to lack of movement, continue until
            // we get far enough away.
            if let radiusPoint = discardRadiusPoint {
                if radiusPoint.distanceKm(between: pt) < StopDetector.ignoreRadiusKm {
                    discardPoints.append(pt)
                    continue
                }

/*
gpsStops.append(GpsStop(points: discardPoints))
var extra = ""
if gpsStops.count > 1 {
    let prev = gpsStops[gpsStops.count - 2]
    let m = Int(1000 * prev.points.last!.distanceKm(between: gpsStops.last!.points.first!))
    extra = "(\(prev.points.last!.seconds(between: gpsStops.last!.points.first!)) seconds, \(m) meters)"
}
print("stop: \(gpsStops.last!) \(extra)")
*/
                discardRadiusPoint = nil
                discardPoints.removeAll(keepingCapacity: true)
            }

            let average = updateAverage(pt)
            pt.movingAverageKmH = average

            // Once our average speed drops, discard points until the stop radius is exceeded
            if pt.movingAverageKmH < StopDetector.tooSlowAverageKmH {
                discardRadiusPoint = pt
                stopPoints.append(pt)
                while let last = movingPoints.last {
                    if pt.distanceKm(between: last) < StopDetector.ignoreRadiusKm 
                            || last.movingAverageKmH < StopDetector.tooSlowAverageKmH {
                        discardPoints.insert(last, at: 0)
                        movingPoints.removeLast()
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
                if movingPoints.count > 0 {
                    PointChanges.analyze(prev: movingPoints.last, point: pt)
                } else {
                    PointChanges.clear(point: pt)
                }
                movingPoints.append(pt)
            }
        }

// for cur in 0..<stopPoints.count {
//     let neighbors = nearbyStops(cur)
//     // print("\(stopPoints[cur]) has \(neighbors.count) neighbors")
// }
        buildClusters()

        stopPoints = stopPoints.filter { notInCluster($0) }
        return movingPoints.filter { notInCluster($0) }
    }

    fileprivate func notInCluster(_ point: GpsPoint) -> Bool {
        for c in clusters {
            if c.contains(point: point) {
                return false
            }
        }
        return true
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

    fileprivate func buildClusters() {
        var clusterPoints = [GpsPoint]()
        for idx in 0..<stopPoints.count-1 {
            let pt = stopPoints[idx]
            let next = stopPoints[idx + 1]
            clusterPoints.append(pt)
            if !isNearby(pt, next) {
                if clusterPoints.count > 2 {
                    self.clusters.append(ClusterStop(points: clusterPoints))
                }
                clusterPoints.removeAll(keepingCapacity: true)
            }
        }

        if clusterPoints.count > 2 {
            self.clusters.append(ClusterStop(points: clusterPoints))
        }

        // For each cluster, check both before and after for any points that ought to be
        // within the cluster, but weren't nearby a neighbor
        for c in clusters {
            var index = findStopIndex(c.points.first!)
            while (index > 0) {
                index -= 1
                if isNearby(stopPoints[index], c.points) {
                    c.extend(point: stopPoints[index])
                } else {
                    break
                }
            }

            index = findStopIndex(c.points.last!)
            while (index > 0 && (index < stopPoints.count - 1)) {
                index += 1
                if isNearby(stopPoints[index], c.points) {
                    c.extend(point: stopPoints[index])
                } else {
                    break
                }
            }
        }
    }

    fileprivate func findStopIndex(_ pt: GpsPoint) -> Int {
        return stopPoints.firstIndex(where: { $0.time == pt.time }) ?? -1
    }

    fileprivate func nearbyStops(_ curIndex: Int) -> [GpsPoint] {
        let curStop = stopPoints[curIndex]
        var neighbors = [GpsPoint]()

        // Find those before this
        var index = curIndex - 1
        while (index >= 0) {
            let pt = stopPoints[index]
            if isNearby(pt, curStop) {
                neighbors.append(pt)
            }
            index -= 1
        }

        /// Find those after this
        index = curIndex + 1
        while (index < stopPoints.count) {
            let pt = stopPoints[index]
            if isNearby(pt, curStop) {
                neighbors.append(pt)
            }
            index += 1
        }

        if neighbors.count > 0 {
            let lat = (curStop.latitude + neighbors.map { $0.latitude }.reduce(0.0, +)) / Double(neighbors.count + 1)
            let lon = (curStop.longitude + neighbors.map { $0.longitude }.reduce(0.0, +)) / Double(neighbors.count + 1)
            let distanceMeters = Int(1000 * Geo.distance(lat1: lat, lon1: lon, lat2: curStop.latitude, lon2: curStop.longitude))
            var minDistance = distanceMeters
            var minSeconds = curStop.seconds(between: neighbors[0])
            for pt in neighbors {
                minDistance = min(pt.distanceMeters(between: curStop), minDistance)
                minSeconds = min(pt.seconds(between: curStop), minSeconds)
            }
            print("\(curStop.time): (\(neighbors.count)), distance from center: \(distanceMeters), min: \(minDistance); "
                + "min seconds: \(minSeconds) [\(lat),\(lon)]")
        }

        return neighbors
    }

    fileprivate func isNearby(_ pt1: GpsPoint, _ points: [GpsPoint]) -> Bool {
        for p in points {
            if isNearby(pt1, p) { return true }
        }
        return false
    }

    fileprivate func isNearby(_ pt1: GpsPoint, _ pt2: GpsPoint) -> Bool {
        let seconds = pt1.seconds(between: pt2)
        let meters = pt1.distanceMeters(between: pt2)
        return seconds < StopDetector.maxClusterSeconds || meters < StopDetector.maxClusterMeters
    }
}
