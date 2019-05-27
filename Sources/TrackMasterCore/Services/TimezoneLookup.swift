import Foundation
import Vapor

public class TimezoneLookupClient {
    static public var timezoneLookupServer: String? = nil

    private let httpCalls: HttpCalls
    private let worker: Worker

    static public func connect(on worker: Worker) -> Future<TimezoneLookupClient> {
        let clientPromise = worker.eventLoop.newPromise(TimezoneLookupClient.self)
        HttpCalls.connect(baseUrl: timezoneLookupServer!, on: worker).do() { client in
            clientPromise.succeed(result: TimezoneLookupClient(httpCalls: client, worker: worker))
        }.catch { error in
            clientPromise.fail(error: error)
        }
        return clientPromise.futureResult
    }

    private init(httpCalls: HttpCalls, worker: Worker) {
        self.httpCalls = httpCalls
        self.worker = worker
    }

    public func close() {
        self.httpCalls.close()
    }

    public func at(lat: Double, lon: Double) -> Future<TimezoneInfo?> {
        let path = "/api/v1/timezone?lat=\(lat)&lon=\(lon)"
        return httpCalls.get(path: path).map(to: TimezoneInfo?.self) { d in
            if let data = d {
                return try TimezoneInfo.decodeFromJson(json: data)
            }
            return nil
        }
    }

}
