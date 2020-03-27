import SwiftyXML

extension GpsPoint {
    static public func from(xml: XML) -> GpsPoint {
        let latitude = xml.$lat.doubleValue
        let longitude = xml.$lon.doubleValue
        let elevation = xml.ele.doubleValue
        let time = Converter.dateTimeFormatter.date(from: xml.time.stringValue)!
        let course = Int(xml.course.doubleValue)
        let speedMs = xml.speed.doubleValue

        return GpsPoint(latitude: latitude, longitude: longitude,
            elevation: elevation, time: time, course: course, speedMs: speedMs)
    }

    public func toXML() -> XML {
        let xml = XML(name: "trkpt", attributes: ["lat": latitude, "lon": longitude])
        xml.addChild(XML(name: "ele", value: elevation))
        xml.addChild(XML(name: "time", value: Converter.dateTimeFormatter.string(from: time)))
        xml.addChild(XML(name: "course", value: calculatedCourse))
        xml.addChild(XML(name: "speed", value: calculatedSpeedMs))

        let extXml = XML(name: "extensions")
        let rangicXml = XML(name: "rangic")
        rangicXml.addChild(XML(name: "calculatedMeters", value: calculatedMeters))
        rangicXml.addChild(XML(name: "calculatedSeconds", value: calculatedSeconds))
        rangicXml.addChild(XML(name: "calculatedSpeedKmh", value: calculatedSpeedKmh))

        let transportation = XML(name: "transportationTypes")
        for tt in transportationTypes {
            transportation.addChild(tt.toXML())
        }
        rangicXml.addChild(transportation)

        extXml.addChild(rangicXml)
        xml.addChild(extXml)

        return xml
    }
}
