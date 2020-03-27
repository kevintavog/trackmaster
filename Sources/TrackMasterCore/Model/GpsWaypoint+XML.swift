import Foundation
import SwiftyXML

extension GpsWaypoint {
    static public func from(xml: XML) -> GpsWaypoint {
        let latitude = xml.$lat.doubleValue
        let longitude = xml.$lon.doubleValue
        let elevation = xml.ele.doubleValue
        let time = Converter.dateTimeFormatter.date(from: xml.time.stringValue)!
        let name = xml.name

        return GpsWaypoint(latitude, longitude, elevation, time, name)
    }

    public func toXML() -> XML {
        let xml = XML(name: "wpt", attributes: ["lat": latitude, "lon": longitude])
        xml.addChild(XML(name: "ele", value: elevation))
        xml.addChild(XML(name: "time", value: Converter.dateTimeFormatter.string(from: time)))
        xml.addChild(XML(name: "name", value: name))

        if let extStop = stop {
            let extXml = XML(name: "extensions")
            let rangicXml = XML(name: "rangic", attributes: ["stopType": extStop.stopType])

            let beginTime = Converter.dateTimeFormatter.string(from: extStop.beginTime)
            let beginXml = XML(
                name: "begin",
                attributes: ["lat": extStop.beginLatitude, "lon": extStop.beginLongitude, "time": beginTime])

            let finishTime = Converter.dateTimeFormatter.string(from: extStop.finishTime)
            let finishXml = XML(
                name: "finish",
                attributes: ["lat": extStop.finishLatitude, "lon": extStop.finishLongitude, "time": finishTime])

            rangicXml.addChild(beginXml)
            rangicXml.addChild(finishXml)
            extXml.addChild(rangicXml)

            xml.addChild(extXml)
        }

        return xml
    }
}
