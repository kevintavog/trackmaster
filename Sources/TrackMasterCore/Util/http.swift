import Foundation

import Vapor
import SwiftyJSON

public class HttpCalls {
    private let httpClient: HTTPClient
    private let worker: Worker

    static public func connect(baseUrl: String, on worker: Worker) -> Future<HttpCalls> {
        let clientPromise = worker.eventLoop.newPromise(HttpCalls.self)
        let url = URLRequest(url: URL(string: baseUrl)!)
        HTTPClient.connect(hostname: url.url!.host!, port: url.url!.port!, on: worker) { error in
            clientPromise.fail(error: error)
        }.do() { client in
            let calls = HttpCalls(client: client, worker: worker)
            clientPromise.succeed(result: calls)
        }.catch { error in
            clientPromise.fail(error: error)
        }
        return clientPromise.futureResult
    }

    private init(client: HTTPClient, worker: Worker) {
        self.httpClient = client
        self.worker = worker
    }

    public func close() {
        self.httpClient.close().do() {
        }.catch() { error in
            print("Error closing HttpCalls http client: \(error)")
        }
    }

    public func getJson(path: String) -> Future<JSON?> {
        return self.get(path: path).map(to: JSON?.self) { data in
            if let d = data {
                return try JSON(data: d)
            }
            return nil
        }
    }

    public func get(path: String) -> Future<Data?> {
        let request = HTTPRequest(method: .GET, url: path)
        return httpClient.send(request).map(to: Data?.self) { response in
            if response.status.code >= 400 {
                let body = String(data: response.body.data ?? Data(), encoding: .utf8) ?? ""
                throw TMError.httpError(status: response.status.code, message: body)
            }
            return response.body.data
        }
    }
}

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
    let givenUrl = URL(string: host)
    if givenUrl == nil {
        throw TMError.invalidParameter(message: "Bad host for url '\(host)'")
    }
    let url = URLRequest(url: givenUrl!)

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
