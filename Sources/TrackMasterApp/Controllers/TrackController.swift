import TrackMasterCore
import Vapor

struct TracksQueryParams: Codable {
    let first: Int?
    let count: Int?
    let startDate: String?
    let endDate: String?
}

final class TrackController {
    func track(_ req: Request) throws -> Future<ControllerTrack> {
        let clientPromise = req.eventLoop.newPromise(ControllerTrack.self)
        let id = try req.parameters.next(String.self).urlEscape()

        ElasticSearchClient.connect(baseUrl: ElasticSearch.ServerUrl, on: req.eventLoop).do() { client in
            client.get(id: id).do() { g in
                if let gps = g {
                    clientPromise.succeed(result: ControllerTrack(gps: gps))
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
            client.get(id: id).do() { g in
                if let gps = g {
                    do {
                        try clientPromise.succeed(result: GpsRepository.loadRaw(path: gps.path))
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
            client.get(id: id).do() { g in
                if let gps = g {
                    do {
                        try clientPromise.succeed(result: GpsRepository.loadOriginal(path: gps.path))
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
            var query = ""
            if let sd = qp.startDate, let ed = qp.endDate {
                query = "startTime:>=\(sd) && endTime:<=\(ed)"
            }

            var first = 0
            if let f = qp.first {
                first = max(0, f - 1)
            }

            client.search(query: query, first: first, count: qp.count ?? 10).do() { searchResponse in
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
