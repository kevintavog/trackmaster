import Foundation


public class CombineSegments {
    private init() {}

    static public func process(_ all: [GpsObject]) -> [GpsObject] {
        var newObjects = [GpsObject]()
        var segmentPoints = [GpsPoint]()
        for idx in 0..<all.count {
            let current = all[idx]
            let secondsBetween = idx == 0 ? 0 : Converter.secondsBetween(all[idx - 1].finishTime, current.beginTime)
            if secondsBetween < GapDetector.maxSecondsBetweenSegments && current.objectType == .segment {
                segmentPoints += (current as! GpsSegment).points
            } else {
                if segmentPoints.count > 0 {
                    newObjects.append(GpsSegment(points: segmentPoints))
                    segmentPoints.removeAll(keepingCapacity: true)
                }

                if current.objectType == .segment {
                    segmentPoints += (current as! GpsSegment).points
                } else {
                    newObjects.append(current)
                }
            }
        }

        if segmentPoints.count > 0 {
            newObjects.append(GpsSegment(points: segmentPoints))
        }

        return newObjects
    }
}
