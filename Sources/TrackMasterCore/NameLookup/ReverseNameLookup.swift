import Foundation
import Vapor

public var ReverseNameLookupServer = ""

public class ReverseNameLookupClient {
    private let httpCalls: HttpCalls
    private let worker: Worker

    static public func connect(baseUrl: String, on worker: Worker) -> Future<ReverseNameLookupClient> {
        let clientPromise = worker.eventLoop.newPromise(ReverseNameLookupClient.self)
        HttpCalls.connect(baseUrl: baseUrl, on: worker).do() { client in
            clientPromise.succeed(result: ReverseNameLookupClient(httpCalls: client, worker: worker))
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

    public func get(lat: Double, lon: Double, distance: Int) -> Future<ReverseNameLookupResponse?> {
        let path = "/api/v1/cached-name?lat=\(lat)&lon=\(lon)&distance=\(distance)&country=true"
        return httpCalls.get(path: path).map(to: ReverseNameLookupResponse?.self) { d in
            if let data = d {
                return try ReverseNameLookupResponse.decodeFromJson(json: data)
            }
            return nil
        }
    }
}
