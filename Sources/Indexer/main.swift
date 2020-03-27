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

func insert(_ client: ElasticSearchClient, _ trackFolder: String, _ url: URL, 
        _ tracks: [GpsTrack], _ waypoints: [GpsWaypoint], _ checksum: String) throws {
    if let gps = GpsAnalyzer().process(
                Gps.relativePath(trackFolder, url),
                tracks,
                waypoints) {
        let indexedGps = ResponseGps(gps: gps, checksum: checksum)
        let _ = try client.index(gps: indexedGps).wait()
        try GpsRepository.save(gps: gps)
    } else {
        print("No worthwhile data, skipping \(url.path.deletingPathPrefix(trackFolder))")
    }

}

private let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)


let createScriptFlag = Flag(shortName: "c", longName: "createScript", type: String.self, description: "The script for creating the ElasticSearch index, if necessary", required: false)
let elasticUrlFlag = Flag(shortName: "e", longName: "elasticUrl", type: String.self, description: "The URL for the ElasticSearch service", required: true)
let forceFlag = Flag(longName: "force", type: Bool.self, description: "Force the updates", required: false)
let analyzedFolderFlag = Flag(shortName: "a", longName: "analyzedFolder", type: String.self, description: "The folder the analyzed GPS files will be written.", required: true)
let maxCountFlag = Flag(longName: "max", type: Int.self, description: "The maximum number of files to parse", required: false)
let reverseNameUrlFlag = Flag(shortName: "r", longName: "reverseNameUrl", type: String.self, description: "The URL for the ReverseName service", required: true)
let singleFileOverrideFlag = Flag(shortName: "s", longName: "singleFile", type: String.self, description: "The single file to process.", required: false)
let skipInsertFlag = Flag(longName: "skipInsert", type: Bool.self, description: "Skip name lookups and inserting into ElasticSearch.", required: false)
let timezoneLookupUrlFlag = Flag(shortName: "z", longName: "timezoneLookupUrl", type: String.self, description: "The URL for the Timezone Lookup service", required: false)
let trackFolderFlag = Flag(shortName: "t", longName: "trackFolder", type: String.self, description: "The folder containing the tracks.", required: true)

let flags = [createScriptFlag, elasticUrlFlag, forceFlag, analyzedFolderFlag, maxCountFlag, 
    reverseNameUrlFlag, singleFileOverrideFlag, skipInsertFlag, timezoneLookupUrlFlag, trackFolderFlag]


let command = Command(usage: "TrackMaster", flags: flags) { flags, args in
    if let createScript = flags.getString(name: "createScript") {
        ElasticSearch.CreateIndexScript = createScript
    }

    ElasticSearch.ServerUrl = flags.getString(name: "elasticUrl")!
    ReverseNameLookupServer = flags.getString(name: "reverseNameUrl")!
    GpsRepository.analyzedFolder = flags.getString(name: "analyzedFolder")
    if let tzLookup = flags.getString(name: "timezoneLookupUrl") {
        TimezoneLookupClient.timezoneLookupServer = tzLookup
    }

    do {
        try ElasticSearch().initialize()
    } catch {
        fail(statusCode: 1, errorMessage: "Failed initializing: \(error)")
    }

    let es = try! ElasticSearchClient.connect(baseUrl: ElasticSearch.ServerUrl, on: eventGroup).wait()
    defer { es.close() }
    let trackFolder = flags.getString(name: "trackFolder")!
    if let singleFile = flags.getString(name: "singleFile") {
        let skipInsert = flags.getBool(name: "skipInsert") ?? false
        if skipInsert {
            ReverseNameLookupServer = ""
        }

        do {
            let (checksum, tracks, waypoints) = try TrackParser.parse(URL(fileURLWithPath: singleFile))
            if skipInsert {
                print("Longer stops:")
                for w in waypoints {
                    if let stop = w.stop {
                        if stop.seconds > 3 * 60 {
                            print("  \(stop.shortBeginTime()) - \(stop.shortFinishTime())")
                        }
                    }
                }
            } else {
                try insert(es, trackFolder, URL(fileURLWithPath: singleFile), tracks, waypoints, checksum)
            }
        } catch {
            fail(statusCode: 2, errorMessage: "Failed processing: \(error)")
        }
    } else {
        do {
            let force = flags.getBool(name: "force") ?? false
            let maxCount = flags.getInt(name: "max") ?? -1
            let files = try enumerateFiles(URL(fileURLWithPath: trackFolder))
            print("Found \(files.count) files")

            var count = 0
            for f in files {
                if try force || ShouldCreateOrUpdate(es, trackFolder, f) {
                    print("Processing \(f.path.deletingPathPrefix(trackFolder))")
                    let (checksum, tracks, waypoints) = try TrackParser.parse(f)
                    try insert(es, trackFolder, f, tracks, waypoints, checksum)
                    count += 1
                    if maxCount >= 0 && count >= maxCount {
                        break
                    }
                }
            }
        } catch {
            fail(statusCode: 2, errorMessage: "Failed processing: \(error)")
        }
    }
}

command.execute()
