import Foundation

public class RunBuilder {
    static public func build(moving: [GpsPoint], stops: [GpsStop]) -> [GpsRun] {
        if stops.count == 0 && moving.count == 0 {
            return [GpsRun]()
        }

        return RunBuilder(stops: stops).build(moving)
    }

    private var points = [GpsPoint]()
    private var runs = [GpsRun]()
    private let stops: [GpsStop]
    private var stopIndex = 0
    private init(stops: [GpsStop]) {
        self.stops = stops
    }

    fileprivate func build(_ moving: [GpsPoint]) -> [GpsRun] {
        for pt in moving {
            checkForNewRun(pt)
            self.points.append(pt)
        }

        addRun()
        return runs
    }

    fileprivate func checkForNewRun(_ pt: GpsPoint) {
        guard let prevPoint = self.points.last else {
            return
        }

        var newRun = false

        // More than 20 seconds between points indicates a gap
        if prevPoint.seconds(between: pt) > 20.0 {
            newRun = true
        }

        if !newRun {
            // A stop between points indicates a gap
            while stopIndex < (stops.count - 1) && stops[stopIndex].startTime < prevPoint.time {
                stopIndex += 1
            }
            newRun = prevPoint.time < stops[stopIndex].startTime && pt.time > stops[stopIndex].startTime
            // for s in stops {
            //     if prevPoint.time <= s.startTime && pt.time >= s.startTime {
            //         newRun = true
            //         break
            //     }
            // }
        }

        if newRun {
            addRun()
            PointChanges.clear(point: pt)
        }
    }

    fileprivate func addRun() {
        if self.points.count > 1 {
            self.runs.append(GpsRun(points: self.points))
        }
        self.points.removeAll(keepingCapacity: true)
    }

}
