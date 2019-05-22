import Foundation
import TrackMasterCore
import Guaka
import Vapor


func ShouldCreateOrUpdate(_ client: ElasticSearchClient, _ base: String, _ inputFile: URL) throws -> Bool {
    let id = inputFile.path.deletingPathPrefix(base).urlEscape()
    do {
        if let track = try client.get(id: id).wait() {
            let checksum = try calculateChecksum(url: inputFile)
            return track.checksum != checksum
        }
        return true
    } catch TMError.httpError(let status, let message) {
        if status != 404 {
            throw TMError.httpError(status: status, message: message)
        }
        return true
    }
}

private let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)


let elasticUrlFlag = Flag(shortName: "e", longName: "elasticUrl", type: String.self, description: "The URL for the ElasticSearch service", required: true)
let reverseNameUrlFlag = Flag(shortName: "r", longName: "reverseNameUrl", type: String.self, description: "The URL for the ReverseName service", required: true)
let trackFolderFlag = Flag(shortName: "t", longName: "trackFolder", type: String.self, description: "The folder containing the tracks.", required: true)
let createScriptFlag = Flag(shortName: "c", longName: "createScript", type: String.self, description: "The script for creating the ElasticSearch index, if necessary", required: false)
let flags = [createScriptFlag, elasticUrlFlag, reverseNameUrlFlag, trackFolderFlag]

let command = Command(usage: "TrackMaster", flags: flags) { flags, args in

    if let createScript = flags.getString(name: "createScript") {
        ElasticSearch.CreateIndexScript = createScript
    }

    ElasticSearch.ServerUrl = flags.getString(name: "elasticUrl")!
    ReverseNameLookupServer = flags.getString(name: "reverseNameUrl")!
    do {
        try ElasticSearch().initialize()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed initializing: \(error)")
    }

    let trackFolder = flags.getString(name: "trackFolder")!
    do {
        let files = try enumerateFiles(URL(fileURLWithPath: trackFolder))
        print("Found \(files.count) files")

        let es = try! ElasticSearchClient.connect(baseUrl: ElasticSearch.ServerUrl, on: eventGroup).wait()

var doFirst = true
        for f in files {
            if try ShouldCreateOrUpdate(es, trackFolder, f) || doFirst {
doFirst = false
                let track = try TrackParser.parse(trackFolder, f)
                let _ = try es.index(track: track).wait()
                print("inserted \(f.path)")
            }
        }
    } catch {
        fail(statusCode: 2, errorMessage: "Failed processing: \(error)")
    }
}

command.execute()
