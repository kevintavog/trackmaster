import Foundation
import TrackMasterCore
import Guaka


let elasticUrlFlag = Flag(shortName: "e", longName: "elasticUrl", type: String.self, description: "The URL for the ElasticSearch service", required: true)
let reverseNameUrlFlag = Flag(shortName: "r", longName: "reverseNameUrl", type: String.self, description: "The URL for the ReverseName service", required: true)
let trackFolderFlag = Flag(shortName: "t", longName: "trackFolder", type: String.self, description: "The folder containing the tracks.", required: true)
let createScriptFlag = Flag(shortName: "c", longName: "createScript", type: String.self, description: "The script for creating the ElasticSearch index, if necessary", required: false)
let flags = [createScriptFlag, elasticUrlFlag, reverseNameUrlFlag, trackFolderFlag]

let command = Command(usage: "TrackMaster", flags: flags) { flags, args in

    if let createScript = flags.getString(name: "createScript") {
        ElasticCreateIndexScript = createScript
    }

    ElasticServer = flags.getString(name: "elasticUrl")!
    ReverseNameLookupServer = flags.getString(name: "reverseNameUrl")!
    do {
        try initElasticSearch()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed initializing: \(error)")
    }

    let trackFolder = flags.getString(name: "trackFolder")!
    do {
        let files = try enumerateFiles(URL(fileURLWithPath: trackFolder))
        print("Found \(files.count) files")

var doFirst = true
        for f in files {
            if try ShouldCreateOrUpdate(trackFolder, f) || doFirst {
doFirst = false
                let track = try TrackParser.parse(trackFolder, f)
                try ElasticSearchClient.index(track: track)
                print("inserted \(f.path)")
            }
        }
    } catch {
        fail(statusCode: 2, errorMessage: "Failed processing: \(error)")
    }
}

command.execute()
