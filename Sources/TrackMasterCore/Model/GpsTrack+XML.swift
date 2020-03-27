import SwiftyXML

extension GpsTrack {

    public func toXML() -> XML {
        let xml = XML(name: "trk")
        for s in segments {
            xml.addChild(s.toXML())
        }

        let extXml = XML(name: "extensions")
        let rangicXml = XML(name: "rangic")

        rangicXml.addChild(XML(name: "kilometers", value: kilometers))
        rangicXml.addChild(XML(name: "seconds", value: seconds))
        rangicXml.addChild(bounds.toXML())

        extXml.addChild(rangicXml)
        xml.addChild(extXml)

        return xml
    }
}
