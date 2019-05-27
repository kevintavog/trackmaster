import Foundation

public class Geo {

    static let radiusEarthKm = 6371.3
    static let oneDegreeLatitudeMeters = 111111.0

    static public func bearingDelta(_ alpha: Int, _ beta: Int) -> Int {
        let phi = abs(beta - alpha) % 360
        return phi > 180 ? 360 - phi : phi
    }

    // Return the distance, in kilometers, between the point and the closest part of the line.
    // Based off https://stackoverflow.com/questions/20231258/minimum-distance-between-a-point-and-a-line-in-latitude-longitude
    static public func distanceToLine(point: GeoPoint, first: GeoPoint, last: GeoPoint) -> Double {
        return Geo.distanceToLine(
            pointLat: point.latitude, pointLon: point.longitude,
            firstLat: first.latitude, firstLon: first.longitude,
            lastLat: last.latitude, lastLon: last.longitude)
    }

    static public func distanceToLine(
                pointLat: Double, pointLon: Double, 
                firstLat: Double, firstLon: Double, lastLat: Double, lastLon: Double) -> Double {
        let fpBearing = Geo.bearing(lat1: firstLat, lon1: firstLon, lat2: pointLat, lon2: pointLon)
        let flBearing = Geo.bearing(lat1: firstLat, lon1: firstLon, lat2: lastLat, lon2: lastLon)
        let distanceFP = Geo.distance(lat1: firstLat, lon1: firstLon, lat2: pointLat, lon2: pointLon)
        return abs(asin(sin(distanceFP / Geo.radiusEarthKm) * sin(Geo.toRadians(degrees: Double(fpBearing - flBearing))))) * Geo.radiusEarthKm
    }

    // Use the small distance calculation (Pythagorus' theorem)
    // See the 'Equirectangular approximation' section of http://www.movable-type.co.uk/scripts/latlong.html
    // The distance returned is in kilometers
    static public func distance(pt1: GeoPoint, pt2: GeoPoint) -> Double {
        return Geo.distance(lat1: pt1.latitude, lon1: pt1.longitude, lat2: pt2.latitude, lon2: pt2.longitude)
    }

    static public func distance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let rLat1 = Geo.toRadians(degrees: lat1)
        let rLon1 = Geo.toRadians(degrees: lon1)
        let rLat2 = Geo.toRadians(degrees: lat2)
        let rLon2 = Geo.toRadians(degrees: lon2)

        let x = (rLon2 - rLon1) * cos((rLat1 + rLat2) / 2)
        let y = rLat2 - rLat1
        return sqrt((x * x) + (y * y)) * radiusEarthKm // radius of earth in kilometers
    }

    // Returns the bearing in degrees: 0-359, with 0 as north and 90 as east
    // From https://www.movable-type.co.uk/scripts/latlong.html
    //      https://github.com/chrisveness/geodesy/blob/master/latlon-spherical.js
    static public func bearing(pt1: GeoPoint, pt2: GeoPoint) -> Int {
        return Geo.bearing(lat1: pt1.latitude, lon1: pt1.longitude, lat2: pt2.latitude, lon2: pt2.longitude)
    }

    static public func bearing(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Int {
        let rLat1 = Geo.toRadians(degrees: lat1)
        let rLat2 = Geo.toRadians(degrees: lat2)
        let rLonDelta = Geo.toRadians(degrees: lon2 - lon1)

        let y = sin(rLonDelta) * cos(rLat2)
        let x = (cos(rLat1) * sin(rLat2)) - (sin(rLat1) * cos(rLat2) * cos(rLonDelta))

        return (Int(Geo.toDegrees(radians: atan2(y, x))) + 360) % 360
    }

    // Returns true if the two rectangles are with the given distance, including overlaps. False otherwise.
    static public func within(meters: Double, first: GeoRectangle, second: GeoRectangle) -> Bool {
        var latOffset: Double = 0.0
        var lonOffset: Double = 0.0
        (latOffset, lonOffset) = Geo.meterOffsetAt(distanceMeters: meters / 2.0, latitude: first.minLat, longitude: first.minLon)

        // Does first intersect with second, using the lat/lon offsets?
        if (first.minLat - latOffset) < second.maxLat
                && (first.maxLat + latOffset) > second.minLat
                && (first.maxLon + lonOffset) > second.minLon
                && (first.minLon - lonOffset) < second.maxLon {
            return true
        }
        return false
    }

    static public func countWithin(rectangle: GeoRectangle, points: [GeoPoint]) -> Int {
        var count = 0
        for p in points {
            if p.latitude >= rectangle.minLat && p.latitude <= rectangle.maxLat
                    && p.longitude >= rectangle.minLon && p.longitude <= rectangle.maxLon {
                count += 1
            }
        }
        return count
    }

    static public func rectangleAround(first: GeoPoint, last: GeoPoint, distanceMeters: Double) -> GeoRectangle {
        let (latOffset, lonOffset) = Geo.meterOffsetAt(distanceMeters: distanceMeters, latitude: first.latitude, longitude: first.longitude)
        return GeoRectangle(
            minLat: min(first.latitude, last.latitude) - latOffset,
            minLon: min(first.longitude, last.longitude) - lonOffset,
            maxLat: max(first.latitude, last.latitude) + latOffset,
            maxLon: max(first.longitude, last.longitude) + lonOffset)
    }

    static public func meterOffsetAt(distanceMeters: Double, latitude: Double, longitude: Double) -> (Double, Double) {
        // From https://gis.stackexchange.com/questions/2951/algorithm-for-offsetting-a-latitude-longitude-by-some-amount-of-meters
        // 111,111 meters is approximately 1 degree latitude
        // 111111 * cos (latitude) is approximately 1 degree longitude
        let latOffset = distanceMeters / oneDegreeLatitudeMeters
        let lonRadians = longitude * Double.pi / 180
        let lonOffset = distanceMeters / (oneDegreeLatitudeMeters * cos(lonRadians))
        return (latOffset, lonOffset)
    }

    static public func toRadians(degrees: Double) -> Double {
        return degrees * Double.pi / 180.0
    }

    static public func toDegrees(radians: Double) -> Double {
        return radians * 180.0 / Double.pi
    }
}
