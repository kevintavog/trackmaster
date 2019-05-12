import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let api = router.grouped("api")

    let trackController = TrackController()
    api.get("tracks", use: trackController.tracks)
    api.get("tracks", String.parameter, use: trackController.track)
}
