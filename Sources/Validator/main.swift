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
            let (chain,removed) = Chain.build(stops: stopDetector.stops, runs: rawRuns)

            let goodRuns = Chain.toRuns(chain: chain)
            // let stops = Chain.toStops(chain: chain)
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
        } catch {
            fail(statusCode: 2, errorMessage: "Failed processing: \(error)")
        }
    }
}

command.execute()
