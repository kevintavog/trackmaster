import Foundation

public enum MovementState: String {
    case huntBelow, accumulateMinBelow, huntAbove, accumulateMinAbove
}

public class MovementDetector {
    public static let minSpeedMetersSecond: Double = 0.320
    public static let minRecoverySpeedMetersSecond: Double = 0.380
    public static let minSeconds = 20.0
    public static let minPoints = 3

    private let originalObjects: [GpsObject]
    private var newObjects = [GpsObject]()

    var firstNotSavedIndex = 0
    var lastAddedIndex = -1
    var belowIndex = -1
    var belowMeters = 0.0

    var aboveIndex = -1
    var aboveMeters = 0.0

    var state = MovementState.huntBelow
    var verbose = false



    private init(_ objects: [GpsObject]) {
        self.originalObjects = objects
    }

    static public func process(_ objects: [GpsObject]) -> [GpsObject] {
        let instance = MovementDetector(objects)
        return instance.process()
    }

    private func process() -> [GpsObject] {
        // Check each point of a segment, adding stops when no or little movement is detected for a long enough time
        for obj in originalObjects {
// print("\(Converter.shortTime(obj.beginTime)) - \(Converter.shortTime(obj.finishTime)); \(obj.objectType); \(obj.label)")
            guard obj.objectType == .segment else {
                appendObject(obj)
                continue
            }

            splitSegment(obj as! GpsSegment)
        }

        return ClusteredStopsDetector.consolidateStops(newObjects)
    }

    private func splitSegment(_ segment: GpsSegment) {
        // Check the speed between the current point and the previous point;
        // when that drops below the minimum, track until:
        //  1. There is enough data to determine very little movement
        //  2. The speed increases, indicating this isn't worth marking

        // Once #1 is detected, continue tracking while the speed is below
        // the minmum. When the speed goes above the minimum track enough data 
        // to determine if it's sustained or a blip; if so, continue tracking.
        // If it's not a blip, create a stop out of the data up to the blip.

        firstNotSavedIndex = 0
        lastAddedIndex = -1
        belowIndex = -1
        belowMeters = 0.0
        aboveIndex = -1
        aboveMeters = 0.0
        state = MovementState.huntBelow

        for idx in 0..<(segment.points.count - 1) {
            let cur = segment.points[idx]

verbose = false && cur.shortTime() >= "23:06:09" && cur.shortTime() <= "23:24:03"
// if verbose {
//     print("\(cur.shortTime()) - \(state), \(cur.calculatedSpeedMs), \(cur.calculatedMeters) [\(belowIndex), \(aboveIndex)]")
// }
            switch state {
            case .huntBelow:
                processHuntBelow(idx, cur)
                break

            case .accumulateMinBelow:
                processAccumulateBelow(idx, cur, segment)
                break

            case .huntAbove:
                processHuntAbove(idx, cur)
                break
            
            case .accumulateMinAbove:
                processAccumulateAbove(idx, cur, segment)
                break
            }
        }


// print("\(Converter.shortTime(segment.beginTime)): end loop: \(state); below: \(belowIndex); above: \(aboveIndex); last added: \(lastAddedIndex) for \(segment)")
        switch state {
        case .huntBelow, .accumulateMinBelow:
            addRemaining(segment)
            break

        case .huntAbove, .accumulateMinAbove:
            addFinalStop(segment)
            break
        }

// TEMP: Check for gaps
        // checkForGaps(segment)
    }

    private func processHuntBelow(_ index: Int, _ current: GpsPoint) {
        if current.calculatedSpeedMs < MovementDetector.minSpeedMetersSecond {
            belowIndex = index
            belowMeters = 0.0
            state = .accumulateMinBelow
        } else {
            if aboveMeters < 0 {
                aboveIndex = index
            }
            aboveMeters += current.calculatedMeters
        }
    }

    private func processAccumulateBelow(_ index: Int, _ current: GpsPoint, _ segment: GpsSegment) {
        let belowSeconds = segment.points[belowIndex].seconds(between: current)
        let countPoints = index - belowIndex
        belowMeters += current.calculatedMeters
        let belowSpeed = belowMeters / belowSeconds
if verbose {
    print("\(current.shortTime()): \(state); \(Int(belowSeconds)) - \(countPoints); \(belowSpeed) m/s; above index: \(aboveIndex)")
}

        if belowSeconds < MovementDetector.minSeconds || countPoints < MovementDetector.minPoints {
            return
        }

        // There is enough data - is the speed still below?
        if belowSpeed >= MovementDetector.minSpeedMetersSecond {
if verbose {
    print("-> (now above speed) \(current.shortTime()): \(belowSpeed); (\(firstNotSavedIndex)) \(belowIndex) and \(aboveIndex)")
}

// BREAKS: Budapest chocolate; start of track: 14:20:41 - 14:22:32 (due to getting into the .accumulatedMinBelow state on the first point)
// FIXES: WalkAndBadSignalSeattle; about 13:09:52 PST - 13:16:20 PST
            if lastAddedIndex >= 0 {
                belowIndex = lastAddedIndex
            }

            belowIndex = firstNotSavedIndex

            // Make sure an above sequence has started
            if aboveIndex < 0 {
                aboveIndex = belowIndex
            }

            // if aboveIndex == -1 {
            //     aboveIndex = 0
            // }
if verbose {
    print("-> \(current.shortTime()): \(belowSpeed); (\(lastAddedIndex)) \(belowIndex) and \(aboveIndex), at \(index) of \(segment.points.count)")
}

//                     if aboveIndex >= 0 && (idx - aboveIndex) >= minPoints {
// print("-> Adding from \(aboveIndex) - \(idx) as segment")
//                         appendObject(GpsSegment(Array(segment.points[aboveIndex...index])))
//                         aboveIndex = index
//                     }

            state = .huntBelow
// print(" --> ignoring potential stop from \(segment.points[belowIndex].shortTime()) - \(current.shortTime()): \(belowSpeed) m/s")
        } else {
            if aboveIndex >= 0 {
                firstNotSavedIndex = belowIndex
                let endAbove = belowIndex - 1
                lastAddedIndex = endAbove
                appendObject(GpsSegment(points: Array(segment.points[aboveIndex...endAbove])))
// let aboveSeconds = segment.points[aboveIndex].seconds(between: segment.points[endAbove])
// let aboveSpeed = aboveMeters / aboveSeconds
// print("SGMT: \(segment.points[aboveIndex].shortTime()) - \(segment.points[endAbove].shortTime()); "
//     + "\(Int(aboveSeconds)) seconds, \(aboveMeters) m, \(aboveSpeed) m/s")
            }
// print("\(segment.points[belowIndex].shortTime()): stop beginning")
            state = .huntAbove
        }
    }

    private func processHuntAbove(_ index: Int, _ current: GpsPoint) {
        if current.calculatedSpeedMs >= MovementDetector.minSpeedMetersSecond {
            aboveIndex = index
            aboveMeters = 0.0
            state = .accumulateMinAbove
// print(" --> \(segment.points[aboveIndex].shortTime()): start of potential segment")
        } else {
            belowMeters += current.calculatedMeters
        }
    }

    private func processAccumulateAbove(_ index: Int, _ current: GpsPoint, _ segment: GpsSegment) {
        let aboveSeconds = segment.points[aboveIndex].seconds(between: current)
        let countPoints = index - aboveIndex
        aboveMeters += current.calculatedMeters

        if aboveSeconds < MovementDetector.minSeconds || countPoints < MovementDetector.minPoints {
            return
        }

        let aboveSpeed = aboveMeters / aboveSeconds
        if aboveSpeed >= MovementDetector.minSpeedMetersSecond {
        let endBelowIndex = aboveIndex - 1
// let belowSeconds = segment.points[belowIndex].seconds(between: segment.points[endBelowIndex])
// let belowSpeed = belowMeters / belowSeconds
// print("STOP: \(segment.points[belowIndex].shortTime()) - \(segment.points[endBelowIndex].shortTime()); "
//     + "\(belowMeters) m")

            firstNotSavedIndex = aboveIndex
            lastAddedIndex = endBelowIndex
            let stopPoints = Array(segment.points[belowIndex...endBelowIndex])
            appendObject(CalculatedStop(.noMovement, 
                stopPoints.first!.latitude, stopPoints.first!.longitude, stopPoints.first!.time,
                stopPoints.last!.latitude, stopPoints.last!.longitude, stopPoints.last!.time))

            state = .huntBelow
        } else {
            state = .huntAbove
        }
    }

    private func addRemaining(_ segment: GpsSegment) {

        // Handle an incomplete .accumulateMinBelow
        if state == .accumulateMinBelow {
            let belowSeconds = segment.points[belowIndex].seconds(between: segment.points.last!)
            let countPoints = segment.points.count - belowIndex
            let belowSpeed = belowMeters / belowSeconds
// print("\(segment.points.first!.shortTime()): [add remaining] \(state) last: \(lastAddedIndex); "
//     + "below seconds: \(belowSeconds); points: \(countPoints); \(belowSpeed) m/s")

            if belowSeconds < MovementDetector.minSeconds 
                    || countPoints < MovementDetector.minPoints
                    || belowSpeed >= MovementDetector.minRecoverySpeedMetersSecond {
                lastAddedIndex = max(lastAddedIndex, 0)
                let numPoints = segment.points.count - lastAddedIndex
                if numPoints >= 1 {
                    let addedPoints = Array(segment.points[lastAddedIndex..<segment.points.count])
                    appendObject(GpsSegment(points: addedPoints))
// print("   -> addRemaining: \(addedPoints.first!.shortTime()) - \(addedPoints.last!.shortTime())")
                    return
                }
            } else {
print("NOT HANDLED - incomplete accumulated min below; should add movement & stop, probably")
            }
        }

        if aboveIndex < 0 && belowIndex < 0 {
            aboveIndex = 0
        } else if aboveIndex < 0 {
            aboveIndex = belowIndex
        }
// let aboveSeconds = segment.points[aboveIndex].seconds(between: segment.points.last!)
// let aboveSpeed = aboveMeters / aboveSeconds
// print("Final (\(state)) is a SEGMENT from \(segment.points[aboveIndex].shortTime()) - \(segment.points.last!.shortTime()); "
//         + "\(Int(aboveSeconds)) seconds, \(aboveMeters) m, \(aboveSpeed) m/s")

        let numPoints = segment.points.count - aboveIndex
        if numPoints >= MovementDetector.minPoints {
            let addedPoints = Array(segment.points[aboveIndex..<segment.points.count])
            appendObject(GpsSegment(points: addedPoints))
// print("   -> addRemaining: \(addedPoints.first!.shortTime()) - \(addedPoints.last!.shortTime())")
        }
    }

    private func addFinalStop(_ segment: GpsSegment) {
// let belowSeconds = segment.points[belowIndex].seconds(between: segment.points.last!)
// let belowSpeed = belowMeters / belowSeconds
// print("Final (\(state)) is a STOP \(segment.points[belowIndex].shortTime()) - \(segment.points.last!.shortTime()); "
//     + "\(belowMeters) m")

        let stopPoints = Array(segment.points[belowIndex..<segment.points.count])
        appendObject(CalculatedStop(.noMovement, 
            stopPoints.first!.latitude, stopPoints.first!.longitude, stopPoints.first!.time,
            stopPoints.last!.latitude, stopPoints.last!.longitude, stopPoints.last!.time))

// print("   -> addFinalStop: \(stopPoints.first!.shortTime()) - \(stopPoints.last!.shortTime())")
    }

    private func appendObject(_ object: GpsObject) {
        if newObjects.count > 0 {
            let prev = newObjects.last!
            let secondsBetween = Converter.secondsBetween(prev.finishTime, object.beginTime)
            if secondsBetween > MovementDetector.minSeconds {
                print(" --> Missing \(Int(secondsBetween)) seconds between \(prev.shortFinishTime()) and \(object.shortBeginTime())")
            }
        }
        newObjects.append(object)
        // print("Added object: \(object.shortBeginTime())-\(object.shortFinishTime()); "
        //     + "\(object.objectType) (\(object.label)); "
        //     + "\(Int(object.seconds)) seconds, \(Int(object.distanceMeters)) meters; "
        //     + "\(object.speedMs) m/s")
    }

    private func checkForGaps(_ segment: GpsSegment) {
        if newObjects.count > 0 && newObjects.first!.beginTime != segment.points.first!.time {
            var secondsDiff = Int(Converter.secondsBetween(segment.points.first!.time, newObjects.first!.beginTime))
            print("  -> Wrong start time, off by \(secondsDiff): Expected \(segment.points.first!.time); actual \(newObjects.first!.beginTime)")
            for idx in 1..<newObjects.count {
                let prev = newObjects[idx - 1]
                let cur = newObjects[idx]
                let expectedStartTime = Date(timeInterval: 1.0, since: prev.finishTime)
                secondsDiff = Int(Converter.secondsBetween(expectedStartTime, cur.beginTime))
                if secondsDiff > 2 {
                    print("  -> Missing time, off by \(secondsDiff): Expected \(expectedStartTime); actual \(cur.beginTime)")
                }
            }

            if newObjects.last!.finishTime != segment.points.last!.time {
                secondsDiff = Int(Converter.secondsBetween(newObjects.last!.finishTime, segment.points.last!.time))
                print("  -> Wrong end time, off by \(secondsDiff): Expected \(segment.points.last!.time); actual \(newObjects.last!.finishTime)")
            }
        }
    }

}
