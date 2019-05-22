
public enum ElasticSearchResultType: String, Codable {
    case created = "created"
    case updated = "updated"
    case deleted = "deleted"
    case notFound = "not_found"
    case noop = "noop"
}

public struct ElasticSearchIndexResponse: Codable {
    public let result: ElasticSearchResultType
}
