import TrackMasterCore
import Vapor

public struct ControllerTracksResponse: Content {
    public let matches: [ControllerTrack]
    public let totalMatches: Int

    public init(searchResponse: SearchTracksResponse) {
        self.matches = searchResponse.matches.map { ControllerTrack(track: $0) }
        self.totalMatches = searchResponse.totalMatches
    }

}
