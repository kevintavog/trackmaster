import Foundation

import Vapor
import SwiftyJSON

private let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

public func httpGetJson(host: String, path: String, parameters: [String:String]?) throws -> JSON? {
    let data = try httpGet(host: host, path: path, parameters: parameters)
    return try JSON(data: data!)
}

public func httpPutJson(host: String, path: String, parameters: [String:String]?, body: Data) throws -> JSON? {
    let data = try httpPut(host: host, path: path, parameters: parameters, body: body)
    return try JSON(data: data!)
}

public func httpGet(host: String, path: String, parameters: [String:String]?) throws -> Data? {
    return try http(method: .GET, host: host, path: path, parameters: parameters, body: nil)
}

public func httpPut(host: String, path: String, parameters: [String:String]?, body: Data) throws -> Data? {
    return try http(method: .PUT, host: host, path: path, parameters: parameters, body: HTTPBody(data: body))
}

private func http(method: HTTPMethod, host: String, path: String, parameters: [String:String]?, body: HTTPBody?) throws -> Data? {
    let url = URLRequest(url: URL(string: host)!)

    var fullPath = path
    if let parms = parameters {
        var first = true
        for p in parms {
            fullPath += "\(first ? "?" : "&")\(p.key)=\(p.value)"
            first = false
        }
    }

    let client = try HTTPClient.connect(hostname: url.url!.host!, port: url.url!.port!, on: eventGroup).wait()
    var request = HTTPRequest(method: method, url: fullPath)
    if let b = body {
        request.body = b
    }
    let response = try client.send(request).wait()
    if isFailure(response.status.code) {
        throw TMError.httpError(status: response.status.code, message: String(data: response.body.data!, encoding: .utf8)!)
    }
    return response.body.data!
}

private func isFailure(_ status: UInt) -> Bool {
    return !isOK(status)
}

private func isOK(_ status: UInt) -> Bool {
    return status >= 200 && status <= 299
}
