import Vapor

public var configuredPort = 8080

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    let serverConfigure = NIOServerConfig.default(hostname: "0.0.0.0", port: configuredPort)
    services.register(serverConfigure)

    // Register middleware
    var middlewares = MiddlewareConfig()
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    middlewares.use(CORSMiddleware(configuration: corsConfiguration))
    middlewares.use(ErrorMiddleware.self)
    services.register(middlewares)

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
}
