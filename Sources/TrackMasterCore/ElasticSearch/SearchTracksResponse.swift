
public struct SearchTracksResponse: Codable {
    public let matches: [ResponseGps]
    public let totalMatches: Int

    public init(matches: [ResponseGps], totalMatches: Int) {
        self.matches = matches
        self.totalMatches = totalMatches
    }
}
