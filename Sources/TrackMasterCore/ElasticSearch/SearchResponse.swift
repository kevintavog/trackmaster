import Foundation

public struct SearchResponse<T: Decodable>: Decodable {
    public let hits: HitsContainer?

    public struct HitsContainer: Decodable {
        public let total: Int
        public let hits: [Hits]

        public struct Hits: Decodable {
            public let _source: T
        }
    }
}
