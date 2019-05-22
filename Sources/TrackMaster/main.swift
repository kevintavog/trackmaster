import TrackMasterApp
import TrackMasterCore
import Guaka


let elasticUrlFlag = Flag(shortName: "e", longName: "elasticUrl", type: String.self, description: "The URL for the ElasticSearch service", required: true)
let trackFolderFlag = Flag(shortName: "t", longName: "trackFolder", type: String.self, description: "The folder containing the tracks.", required: true)
let flags = [elasticUrlFlag, trackFolderFlag]

let command = Command(usage: "TrackMaster", flags: flags) { flags, args in

    ElasticSearch.ServerUrl = flags.getString(name: "elasticUrl")!
    do {
        try ElasticSearch().initialize()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed initializing: \(error)")
    }

    BaseTrackFolder = flags.getString(name: "trackFolder")!
    print("Track folder: \(BaseTrackFolder); ElasticSearch server: \(ElasticSearch.ServerUrl)")
    do {
        try app(.detect(arguments: [CommandLine.arguments[0]])).run()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed server: \(error)")
    }
}

command.execute()
