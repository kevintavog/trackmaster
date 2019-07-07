import Foundation
import XCTest

import TrackMasterCore

class ExpectedCluster {
    static private var _dateTimeFormatter: DateFormatter?
    static public var dateTimeFormatter: DateFormatter {
        get {
            if ExpectedCluster._dateTimeFormatter == nil {
                let dt = DateFormatter()
                dt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                dt.timeZone = TimeZone(secondsFromGMT: 0)
                ExpectedCluster._dateTimeFormatter = dt
            }
            return ExpectedCluster._dateTimeFormatter!
        }
    }

    public let startTime: Date
    public let seconds: Double

    init(_ startTime: String, _ seconds: Double) {
        self.startTime = ExpectedCluster.dateTimeFormatter.date(from: startTime)!
        self.seconds = seconds
    }
}


extension XCTestCase {
    func dataPath(_ filename: String) -> URL {
        return URL(fileURLWithPath: "Tests/TrackMasterTests/Data/\(filename)")
    }

    func parseGpx(_ filename: String) throws -> (Gps?, Track?) {
        return try TrackParser.parse("", dataPath(filename))
    }

    func checkClusters(_ expected: [ExpectedCluster], _ actual: [ClusterStop]) {
        var exIndex = 0
        var acIndex = 0
        while (exIndex < expected.count && acIndex < actual.count) {
            let a = actual[acIndex]
            if acIndex > 0 {
                let prev = actual[acIndex - 1]
                XCTAssertTrue(
                    prev.endTime < a.startTime,
                    "Overlapping result returned: #\(acIndex) \(toISO(prev.endTime)) > \(toISO(a.startTime))")
            }
            XCTAssertEqual(toISO(expected[exIndex].startTime), toISO(a.startTime))
            XCTAssertEqual(expected[exIndex].seconds, a.endTime.timeIntervalSince(a.startTime))
            exIndex += 1
            acIndex += 1
        }
        while (exIndex < expected.count) {
            print("Missing cluster: \(toISO(expected[exIndex].startTime))")
            exIndex += 1
        }
        while (acIndex < actual.count) {
            let a = actual[acIndex]
            let seconds = a.endTime.timeIntervalSince(a.startTime)
            print("Unexpected cluster: \(toISO(a.startTime)), \(seconds)")
            acIndex += 1
        }
        XCTAssertEqual(expected.count, actual.count, "Incorrect number of clusters")
    }

    func toISO(_ date: Date) -> String {
        return ExpectedCluster.dateTimeFormatter.string(from: date)
    }
}
