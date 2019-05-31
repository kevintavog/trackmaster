import Foundation
import Vapor

public class TrackParser {
    static private let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    static private var _reverseClient: ReverseNameLookupClient?
    static private var reverseNameLookupClient: ReverseNameLookupClient {
        get {
            if _reverseClient == nil {
                _reverseClient = try? ReverseNameLookupClient.connect(baseUrl: ReverseNameLookupServer, on: eventGroup).wait()
            }
            return TrackParser._reverseClient!
        }
    }


    private var names = [ReverseNameLookupResponse]()
    private var points = [GpsPoint]()
    private var runs = [GpsRun]()
    private var tracks = [GpsTrack]()
    private var timezoneInfo = TimezoneInfo(id: "", tag: "")
    private init() {
    }

    static public func parse(_ base: String, _ inputFile: URL) throws -> (Gps?, Track?) {
        return try TrackParser().run(base, inputFile)
    }

    fileprivate func run(_ base: String, _ inputFile: URL) throws -> (Gps?, Track?) {
        let fileData = try Data(contentsOf: inputFile)
        let xml = XML(data: fileData)

        let checksum = try calculateChecksum(url: inputFile)

        var allPoints = [GpsPoint]()
        for trk in xml!["trk"] {
            for segment in trk["trkseg"] {
                var prev: GpsPoint? = nil
                for point in segment["trkpt"] {
                    prev = createPoint(prev, point)
                    allPoints.append(prev!)
                }
            }
        }

        let movingPoints = StopFilter.analyze(points: allPoints)
        for pt in movingPoints {
            checkForNewRun(pt)
            self.points.append(pt)
        }
        addRun()
        runs = StopFilter.analyze(runs: runs)

        addTrack()

        if tracks.count == 0 {
            return (nil, nil)
        }

        if TimezoneLookupClient.timezoneLookupServer != nil {
            let firstPoint = tracks.first!.runs.first!.points.first!
            if let client = try? TimezoneLookupClient.connect(on: TrackParser.eventGroup).wait() {
                defer { client.close() }

                if let tz = try? client.at(lat: firstPoint.latitude, lon: firstPoint.longitude).wait() {
                    self.timezoneInfo = tz
                }
            }
        }

// print("stop points:")
// StopFilter.emit()

        let gps = Gps(
            path: inputFile.path.deletingPathPrefix(base),
            tracks: tracks,
            stops: StopFilter.stopPoints,
            tzInfo: timezoneInfo)

print("gps: \(gps)")
for t in gps.tracks {
    print("Track: \(t)")
    var prevRun: GpsRun? = nil
    for r in t.runs {
        var extra = ""
        if let pr = prevRun {
            let gapSeconds = r.points.first!.seconds(between: pr.points.last!)
            let gapMeters = 1000 * r.points.first!.distanceKm(between: pr.points.last!)
            extra = "; \(gapSeconds) second; " +
                "\(Int(gapMeters)) meters gap"
        }
        print("  run: \(r)\(extra)")
        prevRun = r
    }
}

        var distanceKm: Double = 0.0
        addName(tracks.first!.runs.first!.points.first!)
        addName(tracks.last!.runs.last!.points.last!)
        for tr in gps.tracks {
            for run in tr.runs {
                for pt in run.points {
                    distanceKm += pt.kmFromPrevious
                    if distanceKm > 1.0 {
                        addName(pt)
                        distanceKm = 0.0
                    }
                }
            }
        }

        var exportedTrack = Track(
            path: inputFile.path.deletingPathPrefix(base), checksum: checksum, timezoneInfo: gps.timezoneInfo,
            startTime: gps.startTime, endTime: gps.endTime, bounds: gps.bounds)

        // Accumulate all name entries for search weighting
        names.forEach {
            if let sites = $0.sites, sites.count > 0 {
                exportedTrack.siteNames! += sites
            }
            if let city = $0.city {
                exportedTrack.cityNames!.append(city)
            }
            if let state = $0.state {
                exportedTrack.stateNames!.append(state)
            }
            if let countryName = $0.countryName {
                exportedTrack.countryNames!.append(countryName)
            }
            if let code = $0.countryCode {
                exportedTrack.countryCodes!.append(code)
            }
        }

        return (gps, exportedTrack)
    }

    fileprivate func createPoint(_ prev: GpsPoint?, _ xml: XML) -> GpsPoint {
        let latitude = xml["@lat"].doubleValue
        let longitude = xml["@lon"].doubleValue
        let elevation = xml["ele"].doubleValue
        let time = GpsPoint.dateTimeFormatter.date(from: xml["time"].stringValue)!
        let course = Int(xml["course"].doubleValue)
        let speedMs = xml["speed"].doubleValue

        let pt = GpsPoint(latitude: latitude, longitude: longitude,
            elevation: elevation, time: time, course: course, speedMs: speedMs)

        PointChanges.analyze(prev: prev, point: pt)
        return pt
    }

    fileprivate func checkForNewRun(_ pt: GpsPoint) {
        guard let prevPoint = self.points.last else {
            return
        }

        var newRun = false

        // More than 20 seconds
        if prevPoint.seconds(between: pt) > 20.0 {
            newRun = true
        }

        if newRun {
            addRun()
            PointChanges.clear(point: pt)
        }
    }

    fileprivate func addRun() {
        if self.points.count > 1 {
            self.runs.append(GpsRun(points: self.points))
            self.points.removeAll(keepingCapacity: true)
        }
    }

    fileprivate func addTrack() {
        if self.runs.count > 0 {
            self.tracks.append(GpsTrack(runs: self.runs))
            self.runs.removeAll(keepingCapacity: true)
        }
    }

    fileprivate func addName(_ pt: GpsPoint) {
        if ReverseNameLookupServer.count > 0 {
            if let name = try? TrackParser.reverseNameLookupClient.get(lat: pt.latitude, lon: pt.longitude, distance: 500).wait() {
                self.names.append(name)
            }
        }
    }
}