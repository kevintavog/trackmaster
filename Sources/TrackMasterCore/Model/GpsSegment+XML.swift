import SwiftyXML

extension GpsSegment {

    public func toXML() -> XML {
        let xml = XML(name: "trkseg")
        for p in points {
            xml.addChild(p.toXML())
        }

        let extXml = XML(name: "extensions")
        let rangicXml = XML(name: "rangic")

        rangicXml.addChild(XML(name: "kilometers", value: kilometers))
        rangicXml.addChild(XML(name: "kmh", value: kmh))
        rangicXml.addChild(bounds.toXML())

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
