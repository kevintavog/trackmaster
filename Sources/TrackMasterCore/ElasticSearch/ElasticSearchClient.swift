import Foundation

public class ElasticSearchClient {
    private init() {
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