import Foundation
import TrackMasterCore
import Guaka


func parseXml(file: URL) throws -> [GpsPoint] {
    let fileData = try Data(contentsOf: file)
    let xml = XML(data: fileData)
    var allPoints = [GpsPoint]()

    for trk in xml!["trk"] {
        for segment in trk["trkseg"] {
            var prev: GpsPoint? = nil
            for xmlPoint in segment["trkpt"] {
                let pt = GpsPoint.from(xml: xmlPoint)
                PointChanges.analyze(prev: prev, point: pt)
                allPoints.append(pt)
                prev = pt
            }
        }
    }

    return allPoints
}

func buildRuns(points: [GpsPoint]) -> [GpsRun] {
    var pointsInRun = [GpsPoint]()
    var runs = [GpsRun]()
    for pt in points {
        if pointsInRun.count > 0 {
            if pointsInRun.last!.seconds(between: pt) > 20 {
                runs.append(GpsRun(points: pointsInRun))
                pointsInRun.removeAll(keepingCapacity: true)
            }
        }
        pointsInRun.append(pt)
    }
    runs.append(GpsRun(points: pointsInRun))
    return runs
    // return StopFilter.analyze(runs: runs)
}



let inputFlag = Flag(shortName: "i", longName: "input", type: String.self, description: "The file track or folder containing tracks.", required: true)

let flags = [inputFlag]

let command = Command(usage: "Validator", flags: flags) { flags, args in

    let inputName = flags.getString(name: "input")!
    var isFolder: ObjCBool = false
    FileManager.default.fileExists(atPath: inputName, isDirectory: UnsafeMutablePointer<ObjCBool>(&isFolder))

    if isFolder.boolValue {
        print("Handle a folder: \(inputName)")
    } else {
        print("Processing \(inputName)")
        do {
            let allPoints = try parseXml(file: URL(fileURLWithPath: inputName))
            let stopDetector = StopDetector().analyze(points: allPoints)
            let clusters = stopDetector.clusters
            let rawRuns = buildRuns(points: stopDetector.movingPoints)
            let (chain,removed) = Chain.build(stops: stopDetector.stopPoints, runs: rawRuns)

            let goodRuns = Chain.toRuns(chain: chain)
            let stops = Chain.toStops(chain: chain)
            let removedRuns = Chain.toRuns(chain: removed)

print("Kept:")
            for c in goodRuns {
                print("  \(c)")
            }
print("Removed:")
            for r in removedRuns {
                print("  \(r)")
            }
print("Clusters:")
            for c in clusters {
                print("  \(c)")
            }
print("First stop: \(stops.first!.time)")
print("Last stop: \(stops.last!.time)")

/*
            var removed = [ChainLink]()
            var kept = [ChainLink]()
            var prevStop: ChainLink? = nil
            var previousLink: ChainLink? = nil
            for c in chain {
                if c.type == .run {
                    if let ps = prevStop {
                        var prevScore = 0
                        prevScore += ps.count >= 3 ? 1 : 0
                        prevScore += ps.nextSeconds >= 120 ? 1 : 0
                        prevScore += ps.nextMeters >= 20 ? 1 : 0
                        var nextScore = c.nextSeconds >= 15 ? 1 : 0
                        nextScore += c.nextMeters >= 15 ? 1 : 0

                        // Remove this run, combining it with the previous stop
                        if prevScore >= 3 && nextScore >= 1 {
                            removed.append(c)
                            ps.add(link: c)
                            continue
                        }
                    }
                } else {
                    // Combine consecutive stops, which will exist if a run was removed
                    if prevStop != nil && previousLink != nil && previousLink!.type == .stop {
                        prevStop!.add(link: c)
                    } else {
                        prevStop = c
                    }
                }
                if previousLink == nil || (previousLink != nil && previousLink!.type != c.type) {
                    kept.append(c)
                }
                previousLink = c
            }

print("Kept:")
            for k in kept {
                print("  \(k)")
            }
print("Removed:")
            for r in removed {
                print("  \(r)")
            }
*/
        } catch {
            fail(statusCode: 2, errorMessage: "Failed processing: \(error)")
        }
    }
}

command.execute()
