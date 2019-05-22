import Foundation
import Vapor
import SwiftyJSON

struct Search : Codable {
    public let query: String
    public let sort: String
    public let from: Int
    public let size: Int

    init(query: String, sort: String, from: Int, size: Int) {
        self.query = query
        self.sort = sort
        self.from = from
        self.size = size
    }
}

public class ElasticSearchClient {
    private let httpCalls: HttpCalls
    private let worker: Worker

    public static func connect(baseUrl: String, on worker: Worker) -> Future<ElasticSearchClient> {
        let clientPromise = worker.eventLoop.newPromise(ElasticSearchClient.self)
        HttpCalls.connect(baseUrl: baseUrl, on: worker).do() { client in
            let esClient = ElasticSearchClient(client: client, worker: worker)
            clientPromise.succeed(result: esClient)
        }.catch { error in
            clientPromise.fail(error: error)
        }
        return clientPromise.futureResult
    }

    private init(client: HttpCalls, worker: Worker) {
        self.httpCalls = client
        self.worker = worker
    }

    public func close() {
        httpCalls.close()
    }

    public func get(id: String) -> Future<Track?> {
        let path = "/\(ElasticSearch.IndexName)/\(ElasticSearch.TypeName)/\(id)"
        return httpCalls.getJson(path: path).map(to: Track?.self) { j in
            if let json = j {
                if let found = json["found"].bool {
                    if found {
                        return try Track.decodeFromJson(json: json["_source"].rawData())
                    }
                }
            }
            throw TMError.notFound(message: "'\(id)' not found")
        }
    }

    public func search(query: String, first: Int, count: Int) -> Future<SearchTracksResponse> {
        let path = "/\(ElasticSearch.IndexName)/\(ElasticSearch.TypeName)/_search"
        let search = #"{ "sort": { "startTime": "desc" }, "query": { "match_all": {} }, "from": \#(first), "size": \#(count) } "#
        
        let data = search.data(using: .utf8)!
        return httpCalls.post(path: path, body: data).map(to: SearchTracksResponse.self) { d in
            if let data = d {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let response = try decoder.decode(SearchResponse<Track>.self, from: data)
                if let container = response.hits {
                    return SearchTracksResponse(matches: container.hits.map { $0._source }, totalMatches: container.total)
                }
            }
            return SearchTracksResponse(matches: [], totalMatches: 0)
        }
    }

    public func index(track: Track) -> Future<ElasticSearchIndexResponse> {
        do {
            let data = try track.encodeToJson()
            let path = "/\(ElasticSearch.IndexName)/\(ElasticSearch.TypeName)/\(track.id)"
            return httpCalls.put(path: path, body: data).map(to: ElasticSearchIndexResponse.self) { d in
                if let data = d {
                    return try JSONDecoder().decode(ElasticSearchIndexResponse.self, from: data)
                }
                throw TMError.unexpected(message: "index operation returned no data")
            }
        } catch {
            let clientPromise = worker.eventLoop.newPromise(ElasticSearchIndexResponse.self)
            clientPromise.fail(error: TMError.invalidParameter(message: "Can't convert track: \(error)"))
            return clientPromise.futureResult
        }
    }
}
