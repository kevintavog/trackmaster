
extension GpsPoint {
    static public func from(xml: XML) -> GpsPoint {
        let latitude = xml["@lat"].doubleValue
        let longitude = xml["@lon"].doubleValue
        let elevation = xml["ele"].doubleValue
        let time = GpsPoint.dateTimeFormatter.date(from: xml["time"].stringValue)!
        let course = Int(xml["course"].doubleValue)
        let speedMs = xml["speed"].doubleValue

        return GpsPoint(latitude: latitude, longitude: longitude,
            elevation: elevation, time: time, course: course, speedMs: speedMs)
    }
}
