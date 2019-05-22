
public struct SearchTracksResponse: Codable {
    public let matches: [Track]
    public let totalMatches: Int

    public init(matches: [Track], totalMatches: Int) {
        self.matches = matches
        self.totalMatches = totalMatches
    }
}
