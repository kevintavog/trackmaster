import Foundation
import Vapor

public class TrackParser {
    static private let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    static private var _dateTimeFormatter: DateFormatter?
    static public var dateTimeFormatter: DateFormatter {
        get {
            if TrackParser._dateTimeFormatter == nil {
                let dt = DateFormatter()
                dt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                dt.timeZone = TimeZone(secondsFromGMT: 0)
                TrackParser._dateTimeFormatter = dt
            }
            return TrackParser._dateTimeFormatter!
        }
    }

    static private var _reverseClient: ReverseNameLookupClient?
    static private var reverseNameLookupClient: ReverseNameLookupClient {
        get {
            if _reverseClient == nil {
                _reverseClient = try? ReverseNameLookupClient.connect(baseUrl: ReverseNameLookupServer, on: eventGroup).wait()
            }
            return TrackParser._reverseClient!
        }
    }

    static public func parse(_ base: String, _ inputFile: URL) throws -> Track {
        let fileData = try Data(contentsOf: inputFile)
        let xml = XML(data: fileData)

        let checksum = try calculateChecksum(url: inputFile)

        var names = [ReverseNameLookupResponse]()

        var prevLat: Double = 0.0
        var prevLon: Double = 0.0
        var distanceKm: Double = 0.0


        var exportedTrack = Track(path: inputFile.path.deletingPathPrefix(base), checksum: checksum)
        for track in xml!["trk"] {
            for segment in track["trkseg"] {
                for point in segment["trkpt"] {
                    let ptTime = TrackParser.dateTimeFormatter.date(from: point["time"].stringValue)
                    let ptLat = point["@lat"].doubleValue
                    let ptLon = point["@lon"].doubleValue
                    if exportedTrack.startTime == nil {
                        exportedTrack.startTime = ptTime
                        exportedTrack.endTime = ptTime
                        exportedTrack.bounds.min.lat = ptLat
                        exportedTrack.bounds.max.lat = ptLat
                        exportedTrack.bounds.min.lon = ptLon
                        exportedTrack.bounds.max.lon = ptLon
                        TrackParser.addName(ptLat, ptLon, &names)
                        distanceKm = 0.0
                    } else if ptTime != nil {
                        if ptTime! < exportedTrack.startTime! {
                            exportedTrack.startTime = ptTime
                        }
                        if ptTime! > exportedTrack.endTime! {
                            exportedTrack.endTime = ptTime
                        }

                        if ptLat < exportedTrack.bounds.min.lat! {
                            exportedTrack.bounds.min.lat = ptLat
                        } else if ptLat > exportedTrack.bounds.max.lat! {
                            exportedTrack.bounds.max.lat = ptLat
                        }
                        if ptLon < exportedTrack.bounds.min.lon! {
                            exportedTrack.bounds.min.lon = ptLon
                        } else if ptLon > exportedTrack.bounds.max.lon! {
                            exportedTrack.bounds.max.lon = ptLon
                        }
                        distanceKm += Geo.distance(lat1: prevLat, lon1: prevLon, lat2: ptLat, lon2: ptLon)
                        if distanceKm > 1.0 {
                            TrackParser.addName(ptLat, ptLon, &names)
                            distanceKm = 0.0
                        }
                    }
                    prevLat = ptLat
                    prevLon = ptLon
                }
            }
        }

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

        exportedTrack.stateNames = Array(Set(exportedTrack.stateNames!))
        exportedTrack.countryNames = Array(Set(exportedTrack.countryNames!))
        exportedTrack.countryCodes = Array(Set(exportedTrack.countryCodes!))

        return exportedTrack
    }

    static fileprivate func addName(_ lat: Double, _ lon: Double, _ list: inout [ReverseNameLookupResponse]) {

        if let name = try? reverseNameLookupClient.get(lat: lat, lon: lon, distance: 500).wait() {
            list.append(name)
        }
    }
}