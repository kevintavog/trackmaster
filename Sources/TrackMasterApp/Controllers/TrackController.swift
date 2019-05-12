import TrackMasterCore
import Vapor

final class TrackController {
    func track(_ req: Request) throws -> Future<Track> {
        let clientPromise = req.eventLoop.newPromise(Track.self)
        let id = try req.parameters.next(String.self).urlEscape()

        ElasticSearchClient.connect(baseUrl: ElasticServer, on: req.eventLoop).do() { client in
            client.getId(id: id).do() { t in
                if let track = t {
                    clientPromise.succeed(result: track)
                }
            }.catch() { error in
                clientPromise.fail(error: ControllerError(error: error))
            }
        }.catch() { error in
            clientPromise.fail(error: ControllerError(error: error))
        }
        return clientPromise.futureResult
    }

    func tracks(_ req: Request) throws -> Future<[Track]> {
        let t = try ElasticSearchClient.get(id: "%2F2015%2F0912%2Egpx")
        if let track = t {
            return req.future([track])
        } else {
            return req.future([])
        }
    }
}
