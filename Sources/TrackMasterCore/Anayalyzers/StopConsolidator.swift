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
                // If there is a run in between, merge if the stops are close enough (30 meters)
                merge = merge || distance < 30
                // If the run isn't directly connected to one of the stops, merge the stops
                if !merge && distance <= 100 && runs.count == 1 {
                    merge = prevStop.score() >= 2 || runs[0].score() >= 2
                }
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

        return (Chain.toRuns(chain: link), Chain.toStops(chain: link), removedRuns)
    }
}
