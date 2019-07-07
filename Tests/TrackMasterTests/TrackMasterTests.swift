import XCTest
import TrackMasterCore

final class TrackMasterTests: XCTestCase {
    func test_FranceJune25() throws {
        var gps: Gps?
        try when("file parsed") {
            (gps, _) = try parseGpx("2019-06-25.gpx")
        }

        try then("clusters are correct") {
            let expectedClusters = [
                ExpectedCluster("2019-06-25T08:00:47Z", 285.0),
            ]
            checkClusters(expectedClusters, gps!.clusters)
        }
    }

    func test_FranceJune24() throws {
        var gps: Gps?
        try when("file parsed") {
            (gps, _) = try parseGpx("2019-06-24.gpx")
        }

        try then("clusters are correct") {
            let expectedClusters = [
                ExpectedCluster("2019-06-24T06:27:55Z", 77.0),
                ExpectedCluster("2019-06-24T06:33:55Z", 240.0),
                ExpectedCluster("2019-06-24T06:47:54Z", 214.0),
                ExpectedCluster("2019-06-24T09:36:15Z", 93.0),
                ExpectedCluster("2019-06-24T09:42:25Z", 1370.0),
                ExpectedCluster("2019-06-24T10:13:27Z", 121.0),
                ExpectedCluster("2019-06-24T13:03:51Z", 2831.0),
                ExpectedCluster("2019-06-24T14:29:52Z", 3062.0),
                ExpectedCluster("2019-06-24T16:04:18Z", 211.0),
                ExpectedCluster("2019-06-24T16:10:34Z", 520.0),
                ExpectedCluster("2019-06-24T16:41:51Z", 4947.0),
            ]
            checkClusters(expectedClusters, gps!.clusters)
        }
    }

    func test_FranceJune22() throws {
        var gps: Gps?
        try when("file parsed") {
            (gps, _) = try parseGpx("2019-06-22.gpx")
        }

        try then("clusters are correct") {
            let expectedClusters = [
                ExpectedCluster("2019-06-22T08:40:56Z", 331.0),
                ExpectedCluster("2019-06-22T09:28:18Z", 139.0),
                ExpectedCluster("2019-06-22T09:35:39Z", 269.0),
                ExpectedCluster("2019-06-22T09:48:30Z", 218.0),
                ExpectedCluster("2019-06-22T10:03:02Z", 105.0),
                ExpectedCluster("2019-06-22T10:06:52Z", 146.0),
                ExpectedCluster("2019-06-22T10:14:44Z", 8605.0),
                ExpectedCluster("2019-06-22T13:40:43Z", 368.0),
                ExpectedCluster("2019-06-22T13:58:37Z", 146.0),
                ExpectedCluster("2019-06-22T14:22:52Z", 80.0),
                ExpectedCluster("2019-06-22T14:32:36Z", 911.0),
                ExpectedCluster("2019-06-22T15:25:53Z", 5053.0),
                ExpectedCluster("2019-06-22T16:58:53Z", 129.0),
                ExpectedCluster("2019-06-22T17:23:17Z", 91.0),
                ExpectedCluster("2019-06-22T17:40:33Z", 170.0),
                ExpectedCluster("2019-06-22T18:25:49Z", 106.0),
                ExpectedCluster("2019-06-22T18:30:44Z", 192.0),
                ExpectedCluster("2019-06-22T18:44:19Z", 967.0),
                ExpectedCluster("2019-06-22T19:14:07Z", 224.0),
                ExpectedCluster("2019-06-22T19:25:55Z", 372.0),
                ExpectedCluster("2019-06-22T19:34:54Z", 176.0),
                ExpectedCluster("2019-06-22T21:56:13Z", 290.0),
            ]
            checkClusters(expectedClusters, gps!.clusters)
        }
    }
}
