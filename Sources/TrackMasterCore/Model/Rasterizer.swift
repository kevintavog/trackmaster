import Foundation

// Trim to 3 decimal points, store as key to Int
// The int is the number of points OR the amount of time in that cell
// This results in ~111x111 meter cells with either the number of stops
// or the duration (number of seconds).

public class RasterCell: Codable, CustomStringConvertible {
    public let id: String
    public var count: Int = 0
    public var seconds: Double = 0
    public let bounds: Bounds

    public init(id: String, latitude: Double, longitude: Double) {
        self.id = id
        let minLat = RasterCell.convert(latitude)
        let minLon = RasterCell.convert(longitude)
        self.bounds = Bounds(
            minLat: minLat,
            minLon: minLon,
            maxLat: minLat + 0.001,
            maxLon: minLon + 0.001)
    }

    public func categorize(point: GpsPoint) -> RasterCategory {
        return Geo.contains(bounds: bounds, point: point) ? .startsAndEnds : .nothing        
    }

    public func categorize(run: GpsRun) -> RasterCategory {
        let starts = Geo.contains(bounds: bounds, point: run.points.first!)
        let ends = Geo.contains(bounds: bounds, point: run.points.last!)
        if starts && ends {
            return .startsAndEnds
        } else if starts {
            return .starts
        } else if ends {
            return .ends
        }
        return .nothing
    }

    public var description: String {
        return "\(id), \(count) points, \(seconds) seconds"
    }

    static fileprivate func convert(_ x: Double) -> Double {
        return floor(x * 1000) / 1000
    }
    static fileprivate func toId(_ lat: Double, _ lon: Double) -> String {
        return String(format: "%0.3f,%0.3f", convert(lat), convert(lon))
    }
}

public enum RasterCategory: String {
    case starts = "starts"
    case ends = "ends"
    case startsAndEnds = "startsAndEnds"
    case nothing = "nothing"
}

public class Rasterizer {
    private var cells = [String:RasterCell]()
    public let topByDuration: [RasterCell]

    public init(points: [GpsPoint]) {
        for pt in points {
            let id = RasterCell.toId(pt.latitude, pt.longitude)
            if cells[id] == nil {
                cells[id] = RasterCell(id: id, latitude: pt.latitude, longitude: pt.longitude)
            }
            cells[id]!.count += 1
            cells[id]!.seconds += pt.secondsFromPrevious
        }

        self.topByDuration = Array(cells.values.sorted(by: { $0.seconds > $1.seconds }).prefix(8))
    }

    public func dump() {
        let topCount = cells.values.sorted(by: { $0.count > $1.count }).prefix(20)
        print("Rasterizer: there are \(cells.count) cells")
        print("  \(topCount)")
        print("  \(topByDuration)")
    }
}