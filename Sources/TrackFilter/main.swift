import Foundation
import TrackMasterCore
import Guaka
import Vapor


let hourFormatter = DateFormatter()
hourFormatter.dateFormat = "HH:mm"

func isIncluded(_ pointTime: Date, _ startTime: Date, _ endTime: Date) -> Bool {
    // 2019-06-22T08:40:56Z
    // Annoyingly, retrieving the hour from the GpsPoint date, in UTC, returns the hour converted
    // to the local time zone. Avoid that by pulling the HH:MM from the (UTC) string and converting that.
    let pointHMTime = hourFormatter.date(from:  GpsPoint.dateTimeFormatter.string(from: pointTime).subString(11, 15))!
    let point = Calendar.current.dateComponents([.hour, .minute], from: pointHMTime)
    let start = Calendar.current.dateComponents([.hour, .minute], from: startTime)
    let end = Calendar.current.dateComponents([.hour, .minute], from: endTime)

    let afterStart = point.hour! > start.hour! || (point.hour! == start.hour! && point.minute! >= start.minute!)
    let beforeEnd = point.hour! < end.hour! || (point.hour! == end.hour! && point.minute! <= end.minute!)

    return afterStart && beforeEnd
}

func constructXml(_ points: [GpsPoint]) -> String {
    let timeFormatter = ISO8601DateFormatter()

    let bounds = Bounds()

    let segment = XML(name: "trkseg")
    for p in points {
        let px = XML(name: "trkpt")
        bounds.min.latitude = min(p.latitude, bounds.min.latitude)
        bounds.min.longitude = min(p.longitude, bounds.min.longitude)
        bounds.max.latitude = max(p.latitude, bounds.max.latitude)
        bounds.max.longitude = max(p.longitude, bounds.max.longitude)

        px.addAttribute(name: "lat", value: p.latitude)
        px.addAttribute(name: "lon", value: p.longitude)

        px.addChild(XML(name: "ele", value: "\(p.elevation)"))
        px.addChild(XML(name: "time", value: "\(timeFormatter.string(from: p.time))"))
        px.addChild(XML(name: "course", value: "\(p.course)"))
        px.addChild(XML(name: "speed", value: "\(p.speedMs)"))

        segment.addChild(px)
    }

    let boundsEle = XML(name: "bounds")
    boundsEle.addAttribute(name: "minlat", value: bounds.min.latitude)
    boundsEle.addAttribute(name: "minlon", value: bounds.min.longitude)
    boundsEle.addAttribute(name: "maxlat", value: bounds.max.latitude)
    boundsEle.addAttribute(name: "maxlon", value: bounds.max.longitude)

    let track = XML(name: "trk")
    track.addChild(segment)

    let xml = XML(name: "gpx")
    xml.addAttribute(name: "version", value: "1.0")
    xml.addAttribute(name: "xmlns", value: "http://www.topografix.com/GPX/1/0")
    xml.addAttribute(name: "creator", value: "TrackFilter - https://github.com/kevintavog/trackmaster")
    xml.addChild(boundsEle)
    xml.addChild(track)

    return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" + xml.toXMLString()
}


let endTimeFlag = Flag(shortName: "e", longName: "end", type: String.self, description: "The UTC end time, in HH:MM form", required: true)
let inputFileFlag = Flag(shortName: "i", longName: "input", type: String.self, description: "The GPX file to parse", required: true)
let outputFileFlag = Flag(shortName: "o", longName: "output", type: String.self, description: "The file to write to", required: true)
let startTimeFlag = Flag(shortName: "s", longName: "start", type: String.self, description: "The UTC start time, in HH:MM form", required: true)

let flags = [endTimeFlag, inputFileFlag, outputFileFlag, startTimeFlag]

let command = Command(usage: "TrackFilter", flags: flags) { flags, args in

    do {

        let inputFile = flags.getString(name: "input")!
        let outputFile = flags.getString(name: "output")!
        let startString = flags.getString(name: "start")!
        let endString = flags.getString(name: "end")!

        let fileData = try Data(contentsOf: URL(fileURLWithPath: inputFile))
        let xml = XML(data: fileData)

        let startTime = hourFormatter.date(from: startString)!
        let endTime = hourFormatter.date(from: endString)!

        print("Getting points between \(hourFormatter.string(from: startTime)) and \(hourFormatter.string(from: endTime))")


        var filteredPoints = [GpsPoint]()
        for trk in xml!["trk"] {
            for segment in trk["trkseg"] {
                for xmlPoint in segment["trkpt"] {
                    let pt = GpsPoint.from(xml: xmlPoint)
                    if isIncluded(pt.time, startTime, endTime) {
                        filteredPoints.append(pt)
                    }
                }
            }
        }

print("First: \(filteredPoints.first!); last: \(filteredPoints.last!)")

        print("Saving \(filteredPoints.count) points between "
            + "\(hourFormatter.string(from: startTime)) and "
            + "\(hourFormatter.string(from: endTime)) to \(outputFile)")
        let xmlString = constructXml(filteredPoints)
        try xmlString.write(to: URL(fileURLWithPath: outputFile), atomically: false, encoding: .utf8)

    } catch {
        fail(statusCode: 2, errorMessage: "Failed processing: \(error)")
    }
}

command.execute()
