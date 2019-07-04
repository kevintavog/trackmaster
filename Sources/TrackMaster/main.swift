import TrackMasterApp
import TrackMasterCore
import Guaka


let elasticUrlFlag = Flag(shortName: "e", longName: "elasticUrl", type: String.self, description: "The URL for the ElasticSearch service", required: true)
let analyzedFolderFlag = Flag(shortName: "a", longName: "analyzedFolder", type: String.self, description: "The folder the analyzed GPS files will be written.", required: true)
let originalFolderFlag = Flag(shortName: "o", longName: "originalFolder", type: String.self, description: "The folder containing the original tracks.", required: true)

let flags = [elasticUrlFlag, analyzedFolderFlag, originalFolderFlag]

let command = Command(usage: "TrackMaster", flags: flags) { flags, args in

    ElasticSearch.ServerUrl = flags.getString(name: "elasticUrl")!
    GpsRepository.analyzedFolder = flags.getString(name: "analyzedFolder")
    GpsRepository.originalFolder = flags.getString(name: "originalFolder")
    do {
        try ElasticSearch().initialize()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed initializing: \(error)")
    }

    print("Track folder: \(GpsRepository.originalFolder!); ElasticSearch server: \(ElasticSearch.ServerUrl)")
    do {
        try app(.detect(arguments: [CommandLine.arguments[0]])).run()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed server: \(error)")
    }
}

command.execute()
