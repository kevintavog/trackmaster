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


let createScriptFlag = Flag(shortName: "c", longName: "createScript", type: String.self, description: "The script for creating the ElasticSearch index, if necessary", required: false)
let elasticUrlFlag = Flag(shortName: "e", longName: "elasticUrl", type: String.self, description: "The URL for the ElasticSearch service", required: true)
let forceFlag = Flag(longName: "force", type: Bool.self, description: "Force the updates", required: false)
let analyzedFolderFlag = Flag(shortName: "a", longName: "analyzedFolder", type: String.self, description: "The folder the analyzed GPS files will be written.", required: true)
let maxCountFlag = Flag(longName: "max", type: Int.self, description: "The maximum files to parse", required: false)
let reverseNameUrlFlag = Flag(shortName: "r", longName: "reverseNameUrl", type: String.self, description: "The URL for the ReverseName service", required: true)
let singleFileOverrideFlag = Flag(shortName: "s", longName: "singleFile", type: String.self, description: "The single file to process.", required: false)
let skipInsertFlag = Flag(longName: "skipInsert", type: Bool.self, description: "Skip name lookups and inserting into ElasticSearch.", required: false)
let timezoneLookupUrlFlag = Flag(shortName: "z", longName: "timezoneLookupUrl", type: String.self, description: "The URL for the Timezone Lookup service", required: false)
let trackFolderFlag = Flag(shortName: "t", longName: "trackFolder", type: String.self, description: "The folder containing the tracks.", required: true)

let flags = [createScriptFlag, elasticUrlFlag, forceFlag, analyzedFolderFlag, maxCountFlag, 
    reverseNameUrlFlag, skipInsertFlag, singleFileOverrideFlag, timezoneLookupUrlFlag, trackFolderFlag]

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
            let (gps, track) = try TrackParser.parse(trackFolder, URL(fileURLWithPath: singleFile))
            if skipInsert {
                print("Longer stops:")
                for s in gps!.stops {
                    if s.seconds > 3 * 60 {
                        print("  \(s.startTime) - \(s.endTime)")
                    }
                }
            } else {
                if track != nil {
print("inserting track: \(track!)")
                    let _ = try es.index(track: track!).wait()
                    try GpsRepository.save(gps: gps!)
                } else {
                    print("No usable data in \(singleFile)")
                }

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
print("Parsing \(f)")
                    let (gps, track) = try TrackParser.parse(trackFolder, f)
                    if track != nil {
                        let _ = try es.index(track: track!).wait()
                        try GpsRepository.save(gps: gps!)
                        print("inserted \(f.path) - \(track!.id)")
                    } else {
                        print("No usable data in \(f)")
                    }

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
