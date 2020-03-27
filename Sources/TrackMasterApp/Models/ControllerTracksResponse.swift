import TrackMasterCore
import Vapor

public struct ControllerTracksResponse: Content {
    public let matches: [ControllerTrack]
    public let totalMatches: Int

    public init(searchResponse: SearchTracksResponse) {
        self.matches = searchResponse.matches.map { ControllerTrack(gps: $0) }
        self.totalMatches = searchResponse.totalMatches
    }

}
