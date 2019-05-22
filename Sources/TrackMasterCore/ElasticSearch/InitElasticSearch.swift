import Foundation
import Vapor


public class ElasticSearch {
    static public var ServerUrl = ""
    static public var IndexName = "track_index"
    static public var TypeName = "entry"
    static public var CreateIndexScript = "./createIndex.json"

    static private let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

    public init() { }

    public func initialize() throws {
        // Make sure ES exists (get version)
        let client = try HttpCalls.connect(baseUrl: ElasticSearch.ServerUrl, on: ElasticSearch.eventGroup).wait()
        let exists = try client.getJson(path: "").wait()
        print("Using ElasticSearch \(exists!["version"]["number"].string!) host: \(ElasticSearch.ServerUrl)")

        // Make sure `track_master` index exists - create if not
        do {
            let _ = try client.getJson(path: "/\(ElasticSearch.IndexName)/_settings").wait()
        } catch TMError.httpError(let status, let message) {
            if status != 404 {
                throw TMError.httpError(status: status, message: message)
            }
            try createIndex(client)
        }
    }

    private func createIndex(_ client: HttpCalls) throws {
        print("Creating index '\(ElasticSearch.IndexName)'")
        let fileData = try Data(contentsOf: URL(fileURLWithPath: ElasticSearch.CreateIndexScript))
        let _ = try client.putJson(path: "/\(ElasticSearch.IndexName)", body: fileData).wait()
    }
}
