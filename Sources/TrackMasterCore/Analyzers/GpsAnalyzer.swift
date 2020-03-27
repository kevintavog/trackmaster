import Foundation
import Vapor

public class GpsAnalyzer {
    static private let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    static private var _reverseClient: ReverseNameLookupClient?
    static private var reverseNameLookupClient: ReverseNameLookupClient {
        get {
            if _reverseClient == nil {
                _reverseClient = try? ReverseNameLookupClient.connect(baseUrl: ReverseNameLookupServer, on: eventGroup).wait()
            }
            return GpsAnalyzer._reverseClient!
        }
    }

    private var names = [ReverseNameLookupResponse]()


    public init() {}

    public func process(_ path: String, _ tracks: [GpsTrack], _ waypoints: [GpsWaypoint]) -> Gps? {
        PointCalculator.process(tracks)

        var originalObjects = [GpsObject]()
        for t in tracks {
            for s in t.segments {
                if s.points.count > 0 {
                    originalObjects.append(s)
                }
            }
        }

        let gapObjects = GapDetector.process(originalObjects)
        let movingObjects = MovementDetector.process(gapObjects)
        let allSplitSegments = splitSegmentsAtCorners(movingObjects)
        let segmentsAndClusters = ClusteredStopsDetector.process(allSplitSegments)

        let combined = CombineSegments.process(segmentsAndClusters)

        let finalSegments = combined.filter { $0.objectType == .segment }.map { $0 as! GpsSegment }
        let finalWayPoints = combined.filter { $0.objectType == .stop }.map { ($0 as! CalculatedStop).asWaypoint() }

        var finalTracks = [GpsTrack]()
        finalTracks.append(GpsTrack(segments: finalSegments))
        if finalTracks.count < 1
                || finalTracks.first!.segments.count < 1 
                || finalTracks.first!.segments.first!.points.count < 1 {
            return nil
        }

        let timezoneInfo = getTimezoneInfo(finalTracks.first?.segments.first?.points.first)

        let gps = Gps(path: path, tracks: finalTracks, waypoints: finalWayPoints, tzInfo: timezoneInfo)
        addNames(gps)
        return gps
    }

    private func splitSegmentsAtCorners(_ objects: [GpsObject]) -> [GpsObject] {
        var straight = [GpsObject]()
        for o in objects {
            if o.objectType == .segment {
                straight += CornerDetector.process(o as! GpsSegment)
            } else {
                let stop = o as! CalculatedStop
                if stop.stopType != .missingData {
                    straight.append(o)
                }
            }
        }

        return straight
    }

    private func getTimezoneInfo(_ point: GpsPoint?) -> TimezoneInfo {
        if let pt = point {
            if TimezoneLookupClient.timezoneLookupServer != nil {
                if let client = try? TimezoneLookupClient.connect(on: GpsAnalyzer.eventGroup).wait() {
                    defer { client.close() }

                    if let tz = try? client.at(lat: pt.latitude, lon: pt.longitude).wait() {
                        return tz
                    }
                }
            }
        }

print("Returning default timezone")
        return TimezoneInfo(id: "", tag: "")
    }

    private func addNames(_ gps: Gps) {
        var distanceMeters: Double = 0.0
        var seconds: Double = 0.0

        addName(gps.tracks.first!.segments.first!.points.first!)
        addName(gps.tracks.last!.segments.last!.points.last!)
        for tr in gps.tracks {
            for segment in tr.segments {
                for pt in segment.points {
                    distanceMeters += pt.calculatedMeters
                    seconds += pt.calculatedSeconds
                    if distanceMeters > AnalyzerSettings.metersBetweenPlacenames 
                            && seconds > AnalyzerSettings.secondsBetweenPlacenames {
                        addName(pt)
                        distanceMeters = 0.0
                        seconds = 0.0
                    }
                }
            }
        }

        for w in gps.waypoints {
            if (w.stop?.seconds ?? 0) > 3 * 80 {
                addName(w.stop!.centroid())
            }
        }

        // Accumulate all name entries for search weighting
        names.forEach {
            if let sites = $0.sites, sites.count > 0 {
                gps.sites.append(PlacenameSite(names: sites, latitude: $0.latitude, longitude: $0.longitude))
            }
            if let city = $0.city {
                gps.cityNames.append(city)
            }
            if let state = $0.state {
                gps.stateNames.append(state)
            }
            if let countryName = $0.countryName {
                gps.countryNames.append(countryName)
            }
            if let code = $0.countryCode {
                gps.countryCodes.append(code)
            }
        }
    }

    private func addName(_ pt: GeoPoint) {
        if ReverseNameLookupServer.count > 0 {
            if let name = try? GpsAnalyzer.reverseNameLookupClient.get(
                    lat: pt.latitude,
                    lon: pt.longitude,
                    distance: 500).wait() {
                self.names.append(name)
            }
        }
    }
}
