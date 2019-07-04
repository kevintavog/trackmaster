import TrackMasterCore
import Vapor

struct TracksQueryParams: Codable {
    let first: Int?
    let count: Int?
}

final class TrackController {
    func track(_ req: Request) throws -> Future<ControllerTrack> {
        let clientPromise = req.eventLoop.newPromise(ControllerTrack.self)
        let id = try req.parameters.next(String.self).urlEscape()

        ElasticSearchClient.connect(baseUrl: ElasticSearch.ServerUrl, on: req.eventLoop).do() { client in
            client.get(id: id).do() { t in
                if let track = t {
                    clientPromise.succeed(result: ControllerTrack(track: track))
                }
            }.catch() { error in
                clientPromise.fail(error: ControllerError(error: error))
            }
        }.catch() { error in
            clientPromise.fail(error: ControllerError(error: error))
        }
        return clientPromise.futureResult
    }

    func rawTrack(_ req: Request) throws -> Future<String> {
        let clientPromise = req.eventLoop.newPromise(String.self)
        let id = try req.parameters.next(String.self).urlEscape()

        ElasticSearchClient.connect(baseUrl: ElasticSearch.ServerUrl, on: req.eventLoop).do() { client in
            client.get(id: id).do() { t in
                if let track = t {
                    do {
                        try clientPromise.succeed(result: GpsRepository.loadRaw(path: track.path))
                    } catch {
                        clientPromise.fail(error: ControllerError(error: error))
                    }
                }
            }.catch() { error in
                clientPromise.fail(error: ControllerError(error: error))
            }
        }.catch() { error in
            clientPromise.fail(error: ControllerError(error: error))
        }

        return clientPromise.futureResult
    }

    func originalTrack(_ req: Request) throws -> Future<String> {
        let clientPromise = req.eventLoop.newPromise(String.self)
        let id = try req.parameters.next(String.self).urlEscape()

        ElasticSearchClient.connect(baseUrl: ElasticSearch.ServerUrl, on: req.eventLoop).do() { client in
            client.get(id: id).do() { t in
                if let track = t {
                    do {
                        try clientPromise.succeed(result: GpsRepository.loadOriginal(path: track.path))
                    } catch {
                        clientPromise.fail(error: ControllerError(error: error))
                    }
                }
            }.catch() { error in
                clientPromise.fail(error: ControllerError(error: error))
            }
        }.catch() { error in
            clientPromise.fail(error: ControllerError(error: error))
        }

        return clientPromise.futureResult
    }

    func tracks(_ req: Request) throws -> Future<ControllerTracksResponse> {
        let clientPromise = req.eventLoop.newPromise(ControllerTracksResponse.self)
        ElasticSearchClient.connect(baseUrl: ElasticSearch.ServerUrl, on: req.eventLoop).do() { client in
            let qp = try! req.query.decode(TracksQueryParams.self)
            client.search(query: "", first: qp.first ?? 1, count: qp.count ?? 10).do() { searchResponse in
                clientPromise.succeed(result: ControllerTracksResponse(searchResponse: searchResponse))
            }.catch() { error in
                clientPromise.fail(error: ControllerError(error: error))
            }
        }.catch() { error in
            clientPromise.fail(error: ControllerError(error: error))
        }

        return clientPromise.futureResult
    }
}
