
public class CornerPointAccumulator: CustomStringConvertible {
    var points = [GpsPoint]()
    var minLat = 0.0
    var minLon = 0.0
    var maxLat = 0.0
    var maxLon = 0.0

    public init() {
    }

    public func add(_ pt: GpsPoint) {
        if points.count == 0 {
            points.append(pt)
            minLat = pt.latitude
            maxLat = pt.latitude
            minLon = pt.longitude
            maxLon = pt.longitude
        } else {
            points.append(pt)
            minLat = min(minLat, pt.latitude)
            maxLat = max(maxLat, pt.latitude)
            minLon = min(minLon, pt.longitude)
            maxLon = max(maxLon, pt.longitude)
        }
    }

    public func clear() {
        points.removeAll(keepingCapacity: true)
        minLat = 0.0
        maxLat = 0.0
        minLon = 0.0
        maxLon = 0.0
    }

    public func sizeWith(_ pt: GpsPoint) -> (Double, Double) {
        let smallLat = min(minLat, pt.latitude)
        let bigLat =  max(maxLat, pt.latitude)
        let smallLon = min(minLon, pt.longitude)
        let bigLon = max(maxLon, pt.longitude)
        return (bigLon - smallLon, bigLat - smallLat)
    }

    public var width: Double {
        return maxLon - minLon
    }

    public var height: Double {
        return maxLat - minLat
    }

    public var description: String {
        if points.count == 0 {
            return "no points"
        }
        if points.count == 1 {
            return "\(points.first!.shortTime()) - 1 point"
        }

        return "\(points.first!.shortTime()) - \(points.last!.shortTime()); \(points.count) points; "
            + "[\(minLat),\(minLon);\(maxLat),\(maxLon)]; (\(width)x\((height))"
    }

}

public class CornerDetector {
    static let minPointsPerSegment = 10

    private init() {}

    static public func process(_ segment: GpsSegment) -> [GpsObject] {
        let maxSingleAngle = 80
        let maxSmoothedAngle = 30
        // let maxWidth = 30.0 / Geo.oneDegreeLatitudeMeters

        // Split the segments whenever the course/bearing changes enough
        var newSegments = [GpsSegment]()
        let accumulator = CornerPointAccumulator()
        var smoothedBearing = -1
        var recentBearing = -1
        for idx in 0..<segment.points.count {
            let cur = segment.points[idx]
            if accumulator.points.count < 2 {
                accumulator.add(cur)
            } else {
                var lastBearingDelta = 0
                var smoothedBearingDelta = 0
                if accumulator.points.count == 4 {
                    smoothedBearing = accumulator.points.first!.bearing(between: accumulator.points.last!)
                }
                if accumulator.points.count >= 4 {
                    recentBearing = accumulator.points.suffix(idx - 1).first!.bearing(between: cur)
                    smoothedBearingDelta = Geo.bearingDelta(smoothedBearing, recentBearing)
                    lastBearingDelta = Geo.bearingDelta(smoothedBearing, cur.calculatedCourse)
                }

                let deltaBearing = Geo.bearingDelta(accumulator.points.last!.calculatedCourse, cur.calculatedCourse)
                if (deltaBearing > maxSingleAngle && cur.calculatedMeters > 0.5)
                        || lastBearingDelta > maxSmoothedAngle
                        || smoothedBearingDelta > maxSmoothedAngle {

                    newSegments.append(GpsSegment(points: accumulator.points))
                    // Save segment
                    accumulator.clear()
                    smoothedBearing = -1
                    recentBearing = -1
                }
                accumulator.add(cur)
            }
        }

        if accumulator.points.count > 1 {
            newSegments.append(GpsSegment(points: accumulator.points))
        }
        return newSegments
    }

    static public func calculateLoose(_ segment: GpsSegment) -> [GpsObject] {
        let windowSize = 5
        let maxAngle = 60

        if segment.points.count < windowSize {
            return replaceSmallSegments([segment])
        }

        // Split the segments whenever the course/bearing changes enough
        var newSegments = [GpsSegment]()
        var linePoints = [GpsPoint]()
        for idx in 0..<windowSize {
            linePoints.append(segment.points[idx])
        }
        for idx in windowSize..<segment.points.count {
            let cur = segment.points[idx]
            let windowIndex = max(0, linePoints.count - windowSize)
            let deltaBearing = Geo.bearingDelta(linePoints[windowIndex].calculatedCourse, cur.calculatedCourse)
            let lineBearing = linePoints.first!.bearing(between: linePoints.last!)
            let pointLineDelta = Geo.bearingDelta(lineBearing, cur.calculatedCourse)
            // let lineSeconds = linePoints.first!.seconds(between: linePoints.last!)

// Could also average the bearing for each point in the window

            if linePoints.count > minPointsPerSegment 
                    && deltaBearing > maxAngle 
                    || (linePoints.count > 5 && pointLineDelta > maxAngle) {
                if linePoints.count > 1 {
                    newSegments.append(GpsSegment(points: linePoints))
                }
                linePoints.removeAll(keepingCapacity: true)
            }
            linePoints.append(cur)
        }

        if linePoints.count > 1 {
            newSegments.append(GpsSegment(points: linePoints))
        }

        // Stitch together any segments that are close in bearing/course.
        let oldSegments = newSegments
        newSegments = [GpsSegment]()
        newSegments.append(oldSegments.first!)
        for idx in 1..<oldSegments.count {
            let cur = oldSegments[idx]
            let prev = newSegments.last!
            let deltaBearing = Geo.bearingDelta(prev.bearing, cur.bearing)
            let seconds = Int(prev.points.last!.seconds(between: cur.points.first!))
            let meters = Int(prev.points.last!.distanceMeters(between: cur.points.first!))
            if deltaBearing < maxAngle && (seconds < 5 && meters < 10) {
                newSegments.removeLast()
                let combined = GpsSegment(points: prev.points + cur.points)
                newSegments.append(combined)
            } else {
                newSegments.append(cur)
            }
        }

        return newSegments
    }

    static private func replaceSmallSegments(_ segments: [GpsSegment]) -> [GpsObject] {
        var newObjects = [GpsObject]()
        for s in segments {
            if s.points.count > minPointsPerSegment {
                if s.points.count < 4 * minPointsPerSegment {
                    var sharpTurns = 0
                    for idx in 1..<s.points.count {
                        let prev = s.points[idx - 1]
                        let cur = s.points[idx]
                        let course = Geo.bearingDelta(prev.calculatedCourse, cur.calculatedCourse)
                        if course > 80 {
                            sharpTurns += 1
                        }
                    }

                    if sharpTurns >= 3 || sharpTurns > (s.points.count / 2) {
                        newObjects.append(CalculatedStop(
                            .poorData,
                            s.beginLatitude, s.beginLongitude, s.beginTime,
                            s.finishLatitude, s.finishLongitude, s.finishTime))
                    } else {
                        newObjects.append(s)
                    }
                } else {
                    newObjects.append(s)
                }
            } else {
                newObjects.append(CalculatedStop(
                    .poorData,
                    s.beginLatitude, s.beginLongitude, s.beginTime,
                    s.finishLatitude, s.finishLongitude, s.finishTime))
            }
        }

        return newObjects
    }
}