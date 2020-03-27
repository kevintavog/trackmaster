import Foundation

public class GapDetector {
    public static let maxSecondsBetweenSegments: Double = 20
    public static let maxSecondsBetweenPoints: Double = 20
    public static let maxMetersForNoMovementGap = 150

    private init() {}

    static public func process(_ objects: [GpsObject]) -> [GpsObject] {
        var newObjects = [GpsObject]()

        // Add gaps between segments
        newObjects.append(objects[0])
        for idx in 1..<objects.count {
            let prev = objects[idx - 1]
            let cur = objects[idx]
            let secondsBetween = Converter.secondsBetween(prev.finishTime, cur.beginTime)
            let metersBetween = Int(prev.metersBetween(cur))

            if secondsBetween > GapDetector.maxSecondsBetweenSegments {
                let stop = CalculatedStop(metersBetween <= maxMetersForNoMovementGap ? .noMovement : .missingData,
                    prev.finishLatitude, prev.finishLongitude, prev.finishTime,
                    cur.beginLatitude, cur.beginLongitude, cur.beginTime)
                newObjects.append(stop)
            }
            newObjects.append(cur)
        }

        var returnedObjects = [GpsObject]()

        // Split segments to add gaps between points
        for obj in newObjects {
            guard obj.objectType == .segment else {
                returnedObjects.append(obj)
                continue
            }

            let segment = obj as! GpsSegment
            returnedObjects += splitSegment(segment)
        }

        return returnedObjects
    }

    static private func splitSegment(_ segment: GpsSegment) -> [GpsObject] {
        var newObjects = [GpsObject]()
        var segmentStartIndex = 0
        for idx in 1..<segment.points.count {
            let prev = segment.points[idx - 1]
            let cur = segment.points[idx]
            let secondsBetween = prev.seconds(between: cur)
            let metersBetween = Int(prev.distanceMeters(between: cur))
            if secondsBetween > GapDetector.maxSecondsBetweenPoints {
                newObjects.append(GpsSegment(points: Array(segment.points[segmentStartIndex..<idx])))
                segmentStartIndex = idx

                let stop = CalculatedStop(metersBetween <= maxMetersForNoMovementGap ? .noMovement : .missingData,
                    prev.latitude, prev.longitude, prev.time,
                    cur.latitude, cur.longitude, cur.time)
                newObjects.append(stop)
            }
        }

        if segmentStartIndex < (segment.points.count - 1) {
            newObjects.append(GpsSegment(points: Array(segment.points[segmentStartIndex..<segment.points.count])))
        }

        return newObjects
    }
}