import Foundation
import Vapor
import SwiftyJSON

public class ElasticSearchClient {

    private let httpClient: HTTPClient
    private let worker: Worker

    public static func connect(baseUrl: String, on worker: Worker) -> Future<ElasticSearchClient> {
        let clientPromise = worker.eventLoop.newPromise(ElasticSearchClient.self)
        let url = URLRequest(url: URL(string: baseUrl)!)
        HTTPClient.connect(hostname: url.url!.host!, port: url.url!.port!, on: worker) { error in
            clientPromise.fail(error: error)
        }.do() { client in
            let esClient = ElasticSearchClient(client: client, worker: worker)
            clientPromise.succeed(result: esClient)
        }.catch { error in
            clientPromise.fail(error: error)
        }
        return clientPromise.futureResult
    }

    private init(client: HTTPClient, worker: Worker) {
        self.httpClient = client
        self.worker = worker
    }

    public func close() {
        self.httpClient.close().do() {

        }.catch() { error in
            print("Error closing ElasticSearch http client: \(error)")
        }
    }

    public func getId(id: String) -> Future<Track?> {
        let path = "/\(ElasticIndexName)/\(ElasticTypeName)/\(id)"
        let request = HTTPRequest(method: .GET, url: path)
        return httpClient.send(request).map(to: Track?.self) { response in
            var json: JSON
            do {
                json = try JSON(data: response.body.data!)
            } catch {
                throw TMError.httpError(status: response.status.code, message: "Cannot parse response body from Elasticsearch")
            }

            if response.status.code >= 400 {
                var defaultType = "Unknown"
                var defaultReason = "Unknown"
                if response.status.code == 404 {
                    defaultType = "Not found"
                    defaultReason = "Not found"
                }
                let type = json["error"]["type"].string ?? defaultType
                let reason = json["error"]["reason"].string ?? defaultReason
                throw TMError.elasticSearchError(status: response.status.code, type: type, reason: reason)
            }

            if let found = json["found"].bool {
                if found {
                    return try Track.decodeFromJson(json: json["_source"].rawData())
                }
            }
            throw TMError.notFound(message: "'\(id)' not found")
        }
    }


    static public func index(track: Track) throws {
        let data = try track.encodeToJson()
        let _ = try httpPut(host: ElasticServer, path: "/\(ElasticIndexName)/\(ElasticTypeName)/\(track.id)", parameters: nil, body: data)
    }

    static public func get(id: String) throws -> Track? {
        do {
            let response = try httpGetJson(host: ElasticServer, path: "/\(ElasticIndexName)/\(ElasticTypeName)/\(id)", parameters: nil)
            if response?["found"].bool ?? false {
                return try Track.decodeFromJson(json: response!["_source"].rawData())
            }
        } catch TMError.httpError(let status, let message) {
            if status != 404 {
                throw TMError.httpError(status: status, message: message)
            }
        }

        return nil
    }
}
