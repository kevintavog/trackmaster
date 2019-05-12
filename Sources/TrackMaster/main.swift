import TrackMasterApp
import TrackMasterCore
import Guaka


let elasticUrlFlag = Flag(shortName: "e", longName: "elasticUrl", type: String.self, description: "The URL for the ElasticSearch service", required: true)
let trackFolderFlag = Flag(shortName: "t", longName: "trackFolder", type: String.self, description: "The folder containing the tracks.", required: true)
let flags = [elasticUrlFlag, trackFolderFlag]

let command = Command(usage: "TrackMaster", flags: flags) { flags, args in

    ElasticServer = flags.getString(name: "elasticUrl")!
    do {
        try initElasticSearch()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed initializing: \(error)")
    }

    let trackFolder = flags.getString(name: "trackFolder")!
    do {
        try app(.detect(arguments: [CommandLine.arguments[0]])).run()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed server: \(error)")
    }
}

command.execute()
