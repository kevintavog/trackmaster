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

public func reverseNameLookup(lat: Double, lon: Double, distance: Int) -> ReverseNameLookupResponse? {
    if ReverseNameLookupServer == "" {
        print("Skipping reverse name lookup, the server is not set")
        return nil
    }
    do {
        let response = try httpGetJson(
            host: ReverseNameLookupServer,
            path: "/api/v1/cached-name",
            parameters: ["lat": String(lat), "lon": String(lon), "distance": String(distance), "country": String(true)])
        let rnl = try ReverseNameLookupResponse.decodeFromJson(json: response!.rawData())
        if rnl.description != "" {
            return rnl
        }
    } catch {
        // Ignore, it doesn't matter
print("rnl failed: \(error)")
    }
    return nil
}
