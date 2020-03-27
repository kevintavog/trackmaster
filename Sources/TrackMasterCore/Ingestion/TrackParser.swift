import Foundation
import SwiftyXML
import Vapor

public class TrackParser {
    private init() {
    }

    static public func parse(_ inputFile: URL) throws -> (String,[GpsTrack],[GpsWaypoint]) {
        return try TrackParser().parse(inputFile)
    }

    fileprivate func parse(_ inputFile: URL) throws -> (String,[GpsTrack],[GpsWaypoint]) {
        let fileData = try Data(contentsOf: inputFile)
        let checksum = try calculateChecksum(url: inputFile)
        let xml = XML(data: fileData)

        var waypoints = [GpsWaypoint]()
        for wpt in xml!.wpt {
            waypoints.append(GpsWaypoint.from(xml: wpt))
        }

        var tracks = [GpsTrack]()
        for trk in xml!.trk {
            var segments = [GpsSegment]()
            for segment in trk.trkseg {
                var points = [GpsPoint]()
                for xmlPoint in segment.trkpt {
                    let newPoint = GpsPoint.from(xml: xmlPoint)
                    if points.count > 1 {
                        if newPoint.seconds(between: points.last!) > AnalyzerSettings.maxSecondsBetweenPoints {
                            segments.append(GpsSegment(points: points))
                            points.removeAll(keepingCapacity: true)
                        }
                    }
                    points.append(newPoint)
                }
                segments.append(GpsSegment(points: points))
            }
            tracks.append(GpsTrack(segments: segments))
        }

        return (checksum, tracks, waypoints)
    }
}