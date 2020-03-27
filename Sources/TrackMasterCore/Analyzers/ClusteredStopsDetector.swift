import Foundation


/*

    huntStart
        A backPercentage of stop time AND minimum number of (stops + segments)

    huntEnd
        Same basic checks as `huntStart`, but with lower values


*/

public enum ClusterState: String {
    case huntStart, huntEnd
}

private struct ClusterObjectInfo {
    let stopCount: Int
    let stopSeconds: Double
    let segmentCount: Int
    let segmentSeconds: Double
    let oldestIndex: Int

    init(_ stopCount: Int, _ stopSeconds: Double, _ segmentCount: Int, _ segmentSeconds: Double, _ oldestIndex: Int) {
        self.stopCount = stopCount
        self.stopSeconds = stopSeconds
        self.segmentCount = segmentCount
        self.segmentSeconds = segmentSeconds
        self.oldestIndex = oldestIndex
    }
}

public class ClusteredStops {
    var stops = [CalculatedStop]()
    public init() {}

    public func add(_ objects: [GpsObject]) {
        let sorted = objects.sorted { $0.beginTime <= $1.beginTime }
        let first = sorted.first!
        let last = sorted.last!
        let newStop = CalculatedStop(
            .groupedStops,
            first.beginLatitude, first.beginLongitude, first.beginTime,
            last.finishLatitude, last.finishLongitude, last.finishTime)

// print(" --- new stop: \(newStop.shortBeginTime()) - \(newStop.shortFinishTime())")
        var merged = false
        for idx in 0..<stops.count {
            let existing = stops[idx]
// print("      existing \(existing.shortBeginTime()) - \(existing.shortFinishTime())")
            if newStop.secondsBetween(existing) <= 2.0 {
                    stops[idx] = CalculatedStop.merge(.groupedStops, newStop, existing)
                    merged = true
                    break
            }
            if newStop.beginTime >= existing.beginTime && newStop.beginTime <= existing.finishTime {
                    stops[idx] = CalculatedStop.merge(.groupedStops, newStop, existing)
                    merged = true
                    break
            }
            if newStop.beginTime <= existing.beginTime && newStop.finishTime >= existing.beginTime {
                stops[idx] = CalculatedStop.merge(.groupedStops, newStop, existing)
                    merged = true
                break
            }
        }

        if !merged {
            stops.append(newStop)
        }

        for idx in 1..<stops.count {
            let prev = stops[idx - 1]
            let cur = stops[idx]
            if prev.finishTime >= cur.beginTime {
                stops[idx - 1] = CalculatedStop.merge(.groupedStops, prev, cur)
                stops.remove(at: idx)
            }
        }
    }
}

public class ClusteredStopsDetector {
    static public let maxNearbySeconds = 20 * 60.0
    static public let nearbyDistanceMeters = 50.0
    static public let minCountNearbyObjects = 3
    static public let minStartPercentage = 55
    static public let maxEndPercentage = 30

    private init() {}

    static public func process(_ all: [GpsObject]) -> [GpsObject] {
        // let minStopTimeForSegmentCheck = 30.0
        let maxNearbyStopMeters = 15.0
        let maxNearbyCheckSeconds = 10 * 60.0
        let maxNearbySegmentMeters = 10.0

        let clusteredStops = ClusteredStops()

        for idx in 0..<all.count {
            let current = all[idx]

            if current.objectType == .stop {

// if current.shortBeginTime() == "20:30:42" {
//     for x in all {
//         if x.objectType == .stop {
//             let meters = current.metersBetweenCentroid(x)
//             let seconds = current.secondsBetween(x)
//             print("\(x.shortBeginTime()): \(seconds) - \(meters)")
//         }
//     }
// }

                let nearbyStops = all.filter {
                    $0.beginTime != current.beginTime
                    && $0.objectType == .stop
                    && current.secondsBetween($0) < maxNearbyCheckSeconds
                    && current.metersBetweenCentroid($0) < maxNearbyStopMeters
                }

                let nearbySegments = all.filter {
                    $0.objectType == .segment
                    && current.secondsBetween($0) < maxNearbyCheckSeconds
                    && current.metersBetweenCentroid($0) < maxNearbySegmentMeters
                }

                var extra = ""
                if nearbyStops.count > 0 {
                    extra += "; Stops \(nearbyStops.first!.shortBeginTime()) - \(nearbyStops.last!.shortFinishTime())"
                }
                if nearbySegments.count > 0 {
                    extra += "; Segments \(nearbySegments.first!.shortBeginTime()) - \(nearbySegments.last!.shortFinishTime())"
                }

// print("\(current.shortBeginTime()) [\(current.seconds)]: \(nearbyStops.count) stops, total of \(nearbySeconds); "
//     + "\(nearbySegments.count) segments\(extra)")

                if nearbyStops.count > 0 {
                    clusteredStops.add(nearbyStops + nearbySegments)
                }
            }
        }

// print("stops:")
// for s in clusteredStops.stops {
//     print(" - \(s.shortBeginTime()) - \(s.shortFinishTime()) ")
// }

// for o in filterClusters(clusteredStops.stops, all) {
//     print("\(o.shortBeginTime()) - \(o.shortFinishTime()): \(o.objectType); \(o.label)")
// }

        return filterClusters(clusteredStops.stops, all)
    }

    static public func filterClusters(_ clusteredStops: [CalculatedStop], _ objects: [GpsObject]) -> [GpsObject] {
        var newObjects = [GpsObject]()

        var stopIndex = 0
        var objectIndex = 0
        while stopIndex < clusteredStops.count && objectIndex < objects.count {
            let curObject = objects[objectIndex]
            let curStop = clusteredStops[stopIndex]
let verbose = false && curObject.shortBeginTime() <= "14:23:01"
if verbose {
    print("object: \(curObject.shortBeginTime()) - \(curObject.shortFinishTime()); "
        + "stop: \(curStop.shortBeginTime()) - \(curStop.shortFinishTime()); \(newObjects)")
}
            if curObject.finishTime <= curStop.beginTime {
if verbose {
    print(" -- Adding object")
}
                newObjects.append(curObject)
                objectIndex += 1
                continue
            }

            if curObject.beginTime > curStop.finishTime {
if verbose {
    print(" -- Adding stop")
}
                newObjects.append(curStop)
                stopIndex += 1
                continue
            }

if verbose {
    print(" -- Skipping object")
}

            objectIndex += 1
        }

// print("For loops completed, \(objectIndex) of \()")
        if objectIndex < objects.count {
            newObjects += objects[objectIndex..<objects.count]
        }

        return newObjects
    }

    static public func calculateOld(_ all: [GpsObject]) -> [GpsObject] {
        var newObjects = [GpsObject]()
        var state = ClusterState.huntStart
        var keepSegment = true
        var startIndex = -1

        for idx in 0..<all.count {
            let current = all[idx]
            let backStats = statsBack(all, idx)
            let forwardStats = statsForward(all, idx)

            let backNearyObjects = backStats.stopCount + backStats.segmentCount
            let forwardNearyObjects = forwardStats.stopCount + forwardStats.segmentCount


            let backTotalSeconds = backStats.stopSeconds + backStats.segmentSeconds
            let backSpanSeconds = backStats.oldestIndex < 0
                ? 0.0
                : Converter.secondsBetween(all[backStats.oldestIndex].beginTime, current.beginTime)
            let backPercentage = backTotalSeconds <= 1 ? -1 : Int(100.0 * (backStats.stopSeconds / backTotalSeconds))
            let backSpanPercentage = backSpanSeconds <= 1 ? -1 : Int(100.0 * (backStats.stopSeconds / backSpanSeconds))

            let forwardTotalSeconds = forwardStats.stopSeconds + forwardStats.segmentSeconds
            let forwardSpanSeconds = forwardStats.oldestIndex < 0
                ? 0.0
                : Converter.secondsBetween(all[forwardStats.oldestIndex].finishTime, current.finishTime)
            let forwardPercentage = forwardTotalSeconds < 1 ? -1 : Int(100.0 * (forwardStats.stopSeconds / forwardTotalSeconds))
            let forwardSpanPercentage = forwardSpanSeconds <= 1 ? -1 : Int(100.0 * (forwardStats.stopSeconds / forwardSpanSeconds))

var verbose = false
let beginTime = Converter.shortTime(current.beginTime)
if beginTime >= "57:58" || beginTime <= "04:12" {
    verbose = true
}


            // A stop is detected when the preceding nearby objects include at least one stop and N objects
            // AND the upcoming objects include at least one stop and N objects

            switch state {
            case .huntStart:
                if backStats.oldestIndex >= 0 && forwardStats.oldestIndex >= 0 {
                    if backStats.stopCount > 0 && backNearyObjects >= 7
                        && forwardStats.stopCount > 0 && forwardNearyObjects >= 7 {

                    // if backPercentage >= minStartPercentage &&
                    //     (backStats.stopCount + backStats.segmentCount) >= minCountNearbyObjects {
                        state = .huntEnd
                        keepSegment = false
                        startIndex = backStats.oldestIndex + 1

// print("FOUND START - \(Converter.shortTime(all[startIndex].finishTime)) \(backPercentage)%, "
//     + "\(backStats.stopCount) stops & \(backStats.segmentCount) segments --- "
//     + "\(forwardStats.stopCount) stops & \(forwardStats.segmentCount) segments")
                    }
                }
                if keepSegment {
                    newObjects.append(current)
                }
                break

            case .huntEnd:
                // if backTotalSeconds > 0.0 {
                if forwardStats.oldestIndex > 0 {
                    if backStats.stopCount < 1 || backNearyObjects < 7
                        || forwardStats.stopCount < 1 || forwardNearyObjects < 7 {

                    // if backPercentage < maxEndPercentage && (backStats.stopCount + backStats.segmentCount) < minCountNearbyObjects {
                        let startObject = all[startIndex]
                        let endObject = all[forwardStats.oldestIndex]
                        newObjects.append(CalculatedStop(.groupedStops,
                            startObject.beginLatitude, startObject.beginLongitude, startObject.beginTime,
                            endObject.beginLatitude, endObject.beginLongitude, endObject.beginTime))
                        newObjects.append(current)

                        state = .huntStart
                        keepSegment = true
                        startIndex = -1
// print("FOUND END - "
    // + "\(Converter.shortTime(endObject.beginTime)) \(backPercentage)%, "
    // + "\(backStats.stopCount) stops & \(backStats.segmentCount) segments --- "
    // + "\(forwardStats.stopCount) stops & \(forwardStats.segmentCount) segments; "
    // + "From \(Converter.shortTime(startObject.finishTime)) - \(Converter.shortTime(endObject.beginTime)); ")
                    }
                }

                break
            }




            if verbose {

let backFurthestTime = backStats.oldestIndex < 0
    ? "-"
    : Converter.shortTime(all[backStats.oldestIndex].beginTime)
let forwardFurthestTime = forwardStats.oldestIndex < 0
    ? "-"
    : Converter.shortTime(all[forwardStats.oldestIndex].beginTime)

                let message = //current.objectType == .stop
                    // ? " \(state)"
                    // :
                    "B: \(Int(backStats.stopSeconds)) / \(Int(backSpanSeconds)) "
                        + "[\(Int(backTotalSeconds))] seconds; "
                        + "\(Int(backPercentage))% [\(backSpanPercentage)%] in \(backStats.stopCount) stops "
                        + "& \(backStats.segmentCount) segments; \(backFurthestTime) "
                        + "F: \(Int(forwardStats.stopSeconds)) / \(Int(forwardSpanSeconds)) "
                        + "[\(Int(forwardTotalSeconds))] seconds; "
                        + "\(Int(forwardPercentage))% [\(forwardSpanPercentage)%] in \(forwardStats.stopCount) stops "
                        + "& \(forwardStats.segmentCount) segments; \(forwardFurthestTime)"

                // print("\(Converter.shortTime(current.beginTime)) - \(Converter.shortTime(current.finishTime)) "
                //     + "(\(Int(current.seconds))): \(current.objectType); \(message)")
                print("\(Converter.shortTime(current.beginTime)) "
                    + "(\(Int(current.seconds))): \(current.objectType); \(message)")
            }
        }


        if state == .huntStart && startIndex >= 0 && startIndex < all.count {
            let startObject = all[startIndex]
            newObjects.append(CalculatedStop(.groupedStops,
                startObject.beginLatitude, startObject.beginLongitude, startObject.beginTime,
                all.last!.finishLatitude, all.last!.finishLongitude, all.last!.finishTime))
        }

        return consolidateStops(newObjects.sorted(by: {$0.beginTime < $1.beginTime}))
    }

    static public func consolidateStops(_ all: [GpsObject]) -> [GpsObject] {
        var consolidated = [GpsObject]()

        var lastStopIndex = -1
        for idx in 0..<all.count {
            let current = all[idx]
            if current.objectType == .stop { // && (current as! CalculatedStop).stopType != .missingData {
// print("stop: \(Converter.shortTime(current.beginTime)) - \(Converter.shortTime(current.finishTime))")
                if lastStopIndex < 0 {
                    lastStopIndex = idx
                }
            } else {
                if lastStopIndex >= 0 {
                    if (idx - lastStopIndex) >= 1 {
                        var newStop = all[lastStopIndex] as! CalculatedStop
                        for stopIndex in lastStopIndex+1..<idx {
                            newStop = CalculatedStop.merge(newStop.stopType, newStop, all[stopIndex] as! CalculatedStop)
                        }
// print("combine \(lastStopIndex) - \(idx) "
//     + "[\(Converter.shortTime(newStop.beginTime)) - \(Converter.shortTime(newStop.finishTime))]")
                        consolidated.append(newStop)
                        // let lastStop = all[lastStopIndex]
                        // consolidated.append(CalculatedStop(.groupedStops,
                        //     lastStop.beginLatitude, lastStop.beginLongitude, lastStop.beginTime,
                        //     current.beginLatitude, current.beginLongitude, current.beginTime))

                    } else {
                        consolidated.append(all[idx - 1])
                    }
                }
                lastStopIndex = -1
                consolidated.append(current)
            }
        }

        if lastStopIndex >= 0 && (all.count - 1 - lastStopIndex) >= 1 {
            var newStop = all[lastStopIndex] as! CalculatedStop
            for stopIndex in lastStopIndex+1..<all.count {
                newStop = CalculatedStop.merge(newStop.stopType, newStop, all[stopIndex] as! CalculatedStop)
            }
print("[last] combined \(lastStopIndex) to \(all.count - 1) - \(newStop)")
            consolidated.append(newStop)
        }

return consolidated
/*
        var stops = [GpsObject]()
        var response = [GpsObject]()
        for o in consolidated {
            if o.objectType == .stop {
                let matching = stops.filter {
                    o.beginTime >= $0.beginTime && o.beginTime <= $0.finishTime ||
                    o.finishTime <= $0.finishTime && o.finishTime >= $0.beginTime
                }
                if matching.count == 0 {
                    stops.append(o)
                } else {
                    let newStop = CalculatedStop.merge(.groupedStops, o as! CalculatedStop, matching[0] as! CalculatedStop)
                    stops.removeLast()
                    stops.append(newStop)
                }
            } else {
                response.append(o)
            }
        }

        response += stops
        response = response.sorted(by: {$0.beginTime < $1.beginTime})

        return response
*/
    }

    static private func statsForward(_ all: [GpsObject], _ index: Int) -> ClusterObjectInfo {
        return stats(all, index, true)
    }

    static private func statsBack(_ all: [GpsObject], _ index: Int) -> ClusterObjectInfo {
        return stats(all, index, false)
    }

    static private func stats(_ all: [GpsObject], _ index: Int, _ forward: Bool) -> ClusterObjectInfo {
        let current = all[index]
        let earliestTime = Date(timeInterval: -maxNearbySeconds, since: current.beginTime)
        let latestTime = Date(timeInterval: maxNearbySeconds, since: current.finishTime)

let verbose = Converter.shortTime(current.beginTime) == ""
if verbose {
    print("Times from \(earliestTime) to \(latestTime)")
}

        var stopCount = 0
        var stopSeconds = 0.0
        var segmentCount = 0
        var segmentSeconds = 0.0
        var nearbyIdx = forward ? index + 1 : index - 1
        var oldestIndex = -1

        while nearbyIdx >= 0 && nearbyIdx < (all.count - 1) {
            let nearbyObject = all[nearbyIdx]
            if forward {
                nearbyIdx += 1
                if nearbyObject.beginTime > latestTime {
if verbose {
    print("forward time exceeded: \(Converter.shortTime(nearbyObject.beginTime))")
}
                    break
                }
            } else {
                nearbyIdx -= 1
                if nearbyObject.finishTime < earliestTime {
if verbose {
    print("backward time exceeded: \(Converter.shortTime(nearbyObject.finishTime))")
}
                    break
                }
            }


            let midNearbyLat = (nearbyObject.beginLatitude + nearbyObject.finishLatitude) / 2
            let midNearbyLon = (nearbyObject.beginLongitude + nearbyObject.finishLongitude) / 2

            let directMeters = 1000 * Geo.distance(
                lat1: current.finishLatitude, lon1: current.finishLongitude,
                lat2: midNearbyLat, lon2: midNearbyLon)
if verbose {
    let closeEnough = directMeters <= nearbyDistanceMeters
    print("Distance to \(Converter.shortTime(nearbyObject.beginTime)): \(Int(directMeters)) [\(nearbyObject.objectType)] - \(closeEnough)")
}
            if directMeters <= nearbyDistanceMeters {
                oldestIndex = nearbyIdx
                if nearbyObject.objectType == .stop {
                    stopCount += 1
                    stopSeconds += nearbyObject.seconds
                } else {
                    segmentCount += 1
                    segmentSeconds += nearbyObject.seconds
                }
            }
        }

if verbose {
    var spanSeconds = -1.0
    if oldestIndex >= 0 {
        spanSeconds = Converter.secondsBetween(all[oldestIndex].beginTime, all[index].beginTime)
    }
    print("\(forward ? "forward" : "backward"); \(stopCount) -  \(stopSeconds) s; \(segmentCount) - \(segmentSeconds); spanning \(spanSeconds)")
}

        return ClusterObjectInfo(stopCount, stopSeconds, segmentCount, segmentSeconds, oldestIndex)
    }

    static public func format(_ number: Double) -> String {
        return String(format: "%.2f", number)
    }


}
