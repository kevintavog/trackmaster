import Foundation

public var ElasticServer = ""
public var ElasticIndexName = "track_index"
public var ElasticTypeName = "entry"
public var ElasticCreateIndexScript = "./createIndex.json"

public func initElasticSearch() throws {
    // Make sure ES exists (get version)
    let exists = try httpGetJson(host: ElasticServer, path: "", parameters: nil)
    print("Using ElasticSearch \(exists!["version"]["number"].string!) host: \(ElasticServer)")

    // Make sure `track_master` index exists - create if not
    do {
        let _ = try httpGetJson(host: ElasticServer, path: "/\(ElasticIndexName)/_settings", parameters: nil)
    } catch TMError.httpError(let status, let message) {
        if status != 404 {
            throw TMError.httpError(status: status, message: message)
        }
        try createIndex()
    }
}

private func createIndex() throws {
    print("Creating index '\(ElasticIndexName)'")
    let fileData = try Data(contentsOf: URL(fileURLWithPath: ElasticCreateIndexScript))
    let _ = try httpPutJson(host: ElasticServer, path: "/\(ElasticIndexName)", parameters: nil, body: fileData)
}

