import SwiftyXML

extension Gps {

    public func toXML() -> XML {
        let xml = XML(
            name: "gpx",
            attributes: [
                "version": "1.0",
                "creator": "TrackMaster",
                "xmlns": "http://www.topografix.com/GPX/1/0"
            ])

        xml.addChild(XML(name: "time", value: Converter.dateTimeFormatter.string(from: startTime)))
        xml.addChild(bounds.toXML())


        let extXml = XML(name: "extensions")
        let rangicXml = XML(name: "rangic")

        rangicXml.addChild(XML(name: "kilometers", value: kilometers))
        rangicXml.addChild(XML(name: "seconds", value: seconds))
        rangicXml.addChild(XML(name: "movingSeconds", value: movingSeconds))
        rangicXml.addChild(XML(name: "timezoneInfo", attributes: ["id": timezoneInfo.id, "tag": timezoneInfo.tag]))
        rangicXml.addChild(XML(name: "startTime", value: Converter.dateTimeFormatter.string(from: startTime)))
        rangicXml.addChild(XML(name: "endTime", value: Converter.dateTimeFormatter.string(from: endTime)))

        rangicXml.addChild(toXML("countries", "country", countryNames))
        rangicXml.addChild(toXML("countryCodes", "code", countryCodes))
        rangicXml.addChild(toXML("stateNames", "state", stateNames))
        rangicXml.addChild(toXML("cityNames", "city", cityNames))
        rangicXml.addChild(sitesToXml())

        extXml.addChild(rangicXml)
        xml.addChild(extXml)


        for w in waypoints {
            xml.addChild(w.toXML())
        }

        for t in tracks {
            xml.addChild(t.toXML())
        }

        return xml
    }

    private func toXML(_ parentName: String, _ childName: String, _ values: [String]) -> XML {
        let xml = XML(name: parentName)
        for v in values {
            xml.addChild(XML(name: childName, value: v))
        }

        return xml
    }

    private func sitesToXml() -> XML {
        let xml = XML(name: "sites")
        for s in sites {
            var attributes: [String:String] = [:]
            if let lat = s.latitude, let lon = s.longitude {
                attributes["lat"] = String(lat)
                attributes["lon"] = String(lon)
            }
            let xmlSite = XML(name: "site", attributes: attributes)
            for v in s.names {
                xmlSite.addChild(XML(name: "name", value: v))
            }

            xml.addChild(xmlSite)
        }

        return xml
    }
}
