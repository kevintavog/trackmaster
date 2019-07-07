import Foundation

public class StopConsolidator {
    static public func process(chain: [ChainLink], removed: [ChainLink]) -> ([GpsRun],[GpsStop],[GpsRun]) {
        // Grab the first stop
        var lastStopIndex = 0
        while lastStopIndex < chain.count && chain[lastStopIndex].type != .stop {
            lastStopIndex += 1
        }

        var removedRuns = Chain.toRuns(chain: removed)
        var link = chain
        // Find the next stop
        var index = lastStopIndex + 1
        var runs = [ChainLink]()
        while index < link.count {
            if link[index].type == .stop {
                // Are the stops close together? Is there a substantial run in between?
                let prevStop = link[lastStopIndex]
                let curStop = link[index]
                let distance = prevStop.end.distanceMeters(between: curStop.begin)
                let seconds = prevStop.end.seconds(between: curStop.begin)

                let runDistance = Int(1000.0 * runs.reduce(0.0) { $0 + ($1.instance as! GpsRun).kilometers })
                let runDuration = runs.reduce(0.0) { $0 + ($1.instance as! GpsRun).seconds }
                let kmh = Converter.speedKph(seconds: runDuration, kilometers: Double(runDistance) / 1000.0)

                // If there are no runs and they're close enough, merge the stops
                var merge = runs.count == 0 && distance <= 100
                // If they're near each other and the run isn't very long, merge the stops
                // merge = merge || distance <= 25 && runDistance <= 25
merge = merge || distance < 30
                // If the run isn't directly connected to one of the stops, merge the stops
                if !merge && distance <= 100 && runs.count == 1 {
                    merge = prevStop.score() >= 2 || runs[0].score() >= 2
                }
// if !merge {
// let prevDuration = Int(prevStop.begin.seconds(between: prevStop.end))
// let curDuration = Int(curStop.begin.seconds(between: curStop.end))
// print("Compare stops: \(lastStopIndex) & \(index) [\(prevStop.begin.time)]: "
//     + "prev & cur duration:  \(prevDuration) & \(curDuration), "
//     + "\(distance) meters, \(seconds) seconds; "
//     + "run: \(runDistance), \(runDuration), \(Double(Int(100 * kmh)) / 100.0) kmh")
// if runs.count == 1 {
//     print("  stop: \(prevStop) - run: \(runs[0])")
// } else if runs.count > 1 {
//     print("  Consecutive runs? \(runs)")
// }
// }
                if merge {
                    prevStop.add(link: curStop)
                    while index > lastStopIndex {
                        if link[index].type == .run {
                            removedRuns.append(link[index].instance as! GpsRun)
                        }
                        link.remove(at: index)
                        index -= 1
                    }
                    index = lastStopIndex
                } else {
                    lastStopIndex = index
                }

                runs.removeAll(keepingCapacity: true)
            } else {
                runs.append(link[index])
            }
            index += 1
        }

// print("Started with \(Chain.toRuns(chain:chain).count) runs & \(Chain.toStops(chain:chain).count) stops, "
//     + "Filtered to \(Chain.toRuns(chain:link).count) runs & \(Chain.toStops(chain:link).count) stops")

/*
print("Removed runs:")
for r in removedRuns {
    print(" \(r.points.first!.time)")
}

print("Stops:")
for s in Chain.toStops(chain: link) {
    print(" \(s.startTime) - \(s.endTime)")
}
*/

// print("Chain (want one stop from 19:40:41 - 21:51:34 (local: 21:40:41 - 23:51:34)")
// for index in 0..<link.count - 1 {
//     let cur = link[index ]
//     let next = link[index + 1]
//     let duration = Int(cur.end.seconds(between: next.begin))
//     let distance = cur.end.distanceMeters(between: next.begin)
//     print(" \(cur.type); \(cur.begin.time) - \(cur.end.time); \(duration), \(distance)")
// }

        return (Chain.toRuns(chain: link), Chain.toStops(chain: link), removedRuns)
    }
}
