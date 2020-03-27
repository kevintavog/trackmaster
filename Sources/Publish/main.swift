import Foundation
import TrackMasterCore
import Guaka
import SwiftyJSON
import Vapor


private let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)


let outputFolderFlag = Flag(shortName: "o", longName: "outputFolder", type: String.self,
    description: "The folder to publish to", required: true)
let publishListFlag = Flag(shortName: "p", longName: "publishList", type: String.self,
    description: "The file containing the list of tracks to publish (each line is the path of the file to publish)",
    required: true)
let trackManagerUrlFlag = Flag(shortName: "t", longName: "trackManagerUrl", type: String.self,
    description: "The URL for the TrackManager service", required: true)

let flags = [outputFolderFlag, publishListFlag, trackManagerUrlFlag]

let command = Command(usage: "Publish", flags: flags) { flags, args in

    let tmUrl = flags.getString(name: "trackManagerUrl")!

    let tm = try! HttpCalls.connect(baseUrl: tmUrl, on: eventGroup).wait()
    defer { tm.close() }

    let outputFolder = flags.getString(name: "outputFolder")!
    let docsFolder = outputFolder + "/documents"
    let rawFolder = outputFolder + "/raw"
    let publishListFile = flags.getString(name: "publishList")!

    do {
        // Ensure the output folder is empty
        if FileManager.default.fileExists(atPath: outputFolder) {
            try FileManager.default.removeItem(atPath: outputFolder)
        }
        try FileManager.default.createDirectory(atPath: outputFolder, withIntermediateDirectories: false)
        try FileManager.default.createDirectory(atPath: docsFolder, withIntermediateDirectories: false)
        try FileManager.default.createDirectory(atPath: rawFolder, withIntermediateDirectories: false)

        var matches = [JSON]()
        var lineNumber = 0
        let lines = try String(contentsOfFile: publishListFile).split(separator: "\n")
        for path in lines {
            lineNumber += 1
            let trimmed = path.trimmingCharacters(in: .whitespaces)
            if trimmed.count == 0 || trimmed.hasPrefix("#") {
                continue
            }

            let id = trimmed.urlEscape()
            do {
                let track = try tm.getJson(path: "/api/tracks/\(id)").wait()!
                let docName = track["path"].stringValue.filter { $0 != "/" && $0 != "-" } + ".json"
                try track.rawData().write(to: URL(fileURLWithPath: "\(docsFolder)/\(docName)"))
                matches.append(track)

                let rawTrack = try tm.get(path: "/api/tracks/\(id)/raw").wait()!
                try rawTrack.write(to: URL(fileURLWithPath: "\(rawFolder)/\(docName)"))
            } catch {
                print("Unable to find a matching track: \(trimmed), from line #\(lineNumber) [\(path)]. Error: \(error)")
            }
        }

        var list = JSON()
        list["matches"].arrayObject = matches
        list["totalMatches"].intValue = matches.count
        try list.rawString()!.write(to: URL(fileURLWithPath: "\(outputFolder)/list.json"), atomically: true, encoding: .utf8)
    } catch {
        fail(statusCode: 2, errorMessage: "Failed processing: \(error)")
    }
}

command.execute()
