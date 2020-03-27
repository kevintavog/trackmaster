/*
import Foundation

public enum ChainLinkType: String, Codable {
    case stop = "stop"
    case run = "run"
}

public class ChainLink: CustomStringConvertible {
    public var begin: GpsPoint
    public var end: GpsPoint
    public let type: ChainLinkType
    public let instance: Any
    public var recentStops = 0
    public var recentDistanceMeters = 0

    public var nextSeconds: Double = 0
    public var nextMeters: Int = 0
    public var nextStopSeconds: Double = 0
    public var nextStopMeters: Int = 0


    public init(begin: GpsPoint, end: GpsPoint, type: ChainLinkType, instance: Any) {
        self.begin = begin
        self.end = end
        self.type = type
        self.instance = instance
    }

    // Qualify the connection between this link and the link it's connected to.
    // If it's a poor connection (close, but not close enough), it'll score higher.
    // If it's so far away from the next link, it'll return a low score - as it likely
    // indicates missing data (due to tunnels, etc)
    public func score() -> Int {
        var score = 0
        if nextMeters >= 200 {
            return 0
        }
        score += nextSeconds >= 15 ? 1 : 0
        score += nextMeters >= 15 ? 1 : 0
        return score
    }

    public func add(link: ChainLink) {
        if type != .stop && link.type != .stop {
print("Ignoring request to add \(type) and \(link.type)")
            return
        }

        let thisStop = instance as! GpsStop
        let linkStop = link.instance as! GpsStop
        thisStop.extend(stop: linkStop)

        if link.end.time > end.time {
            end = link.end
            nextSeconds += link.nextSeconds
            nextMeters += link.nextMeters
        }
        if link.end.time < begin.time {
print("new end earlier than my begin!!!")
        }
    }

    public var description: String {
        var extra = ""
        if type == .stop {
            extra = "stop: \(nextStopMeters) m, \(nextStopSeconds) s, "
                + "rs=\(recentStops), rsm=\(recentDistanceMeters)"
        }
        return "\(type) \(begin.time), next: \(nextMeters) m, \(nextSeconds) s, "
            + "\(extra); \(instance)"
    }
}

public class Chain {

    static public func toRuns(chain: [ChainLink]) -> ([GpsRun]) {
        return chain.filter { $0.type == .run }.map { $0.instance as! GpsRun }
    }

    static public func toStops(chain: [ChainLink]) -> ([GpsStop]) {
        return chain.filter { $0.type == .stop }.map { $0.instance as! GpsStop }
    }

    /*  Create a simple chain of stops & runs, in time order.
        Distance and time offsets (meters & seconds) are calculated between consecutive items.
        Likely bad runs are removed.
     */
    static public func build(stops: [GpsStop], runs: [GpsRun]) -> ([ChainLink],[ChainLink]) {
        if stops.count == 0 && runs.count == 0 {
            return ([ChainLink](), [ChainLink]())
        }

        let builder = Chain(stops, runs)
        builder.orderByTime()
        builder.calculateOffsets(builder.ordered)
        builder.removeBadRuns()
        builder.calculateOffsets(builder.finalChain)
        return (builder.finalChain, builder.removedLinks)
    }

    private let stops: [GpsStop]
    private let runs: [GpsRun]
    private var ordered = [ChainLink]()
    private var removedLinks = [ChainLink]()
    private var finalChain = [ChainLink]()
    private var recentStops = [ChainLink]()
    private init(_ stops: [GpsStop], _ runs: [GpsRun]) {
        self.stops = stops
        self.runs = runs
    }

    // Bad runs are:
    //   Disconnected on both ends, from both stops & runs
    fileprivate func removeBadRuns() {
        var previousLink: ChainLink? = nil
        for c in ordered {
            var append = true
            if c.type == .run {
                if let prev = previousLink {
                    let prevScore = prev.score()
                    let nextScore = c.score()

                    // If this run is disconnected on both ends, remove it
                    if prevScore >= 2 && nextScore >= 2 {
// print("Removing \(c)")
                        removedLinks.append(c)
                        append = false
                    }
                }
            }
            if append { finalChain.append(c) }
            previousLink = c
        }
    }

    fileprivate func orderByTime() {
        var runIndex = 0
        var stopIndex = 0

        while (runIndex < runs.count || stopIndex < stops.count) {
            var beginPoint: GpsPoint? = nil
            var endPoint: GpsPoint? = nil
            var type: ChainLinkType = .stop
            var instance: Any? = nil
            if runIndex < runs.count && stopIndex >= stops.count {
                type = .run
                beginPoint = runs[runIndex].points.first!
                endPoint = runs[runIndex].points.last!
                instance = runs[runIndex]
                runIndex += 1
            } else if stopIndex < stops.count && runIndex >= runs.count {
                type = .stop
                beginPoint = stops[stopIndex].firstPoint
                endPoint = stops[stopIndex].lastPoint
                instance = stops[stopIndex]
                stopIndex += 1
            } else {
                let r = runs[runIndex]
                let s = stops[stopIndex]
                if r.points.first!.time < s.startTime {
                    type = .run
                    beginPoint = r.points.first!
                    endPoint = r.points.last!
                    instance = r
                    runIndex += 1
                } else {
                    type = .stop
                    beginPoint = s.firstPoint
                    endPoint = stops[stopIndex].lastPoint
                    instance = s
                    stopIndex += 1
                }
            }

            let link = ChainLink(begin: beginPoint!, end: endPoint!, type: type, instance: instance!)
            updateRecent(link)
            ordered.append(link)
        }
    }

    fileprivate func calculateOffsets(_ chain: [ChainLink]) {
        for idx in 0..<chain.count-1 {
            let cur = chain[idx]
            let next = chain[idx + 1]
            cur.nextSeconds = cur.end.seconds(between: next.begin)
            cur.nextMeters = Int(1000 * cur.end.distanceKm(between: next.begin))
        }
        calculateStopOffsets(chain)
    }

    fileprivate func calculateStopOffsets(_ chain: [ChainLink]) {
        var prevStop: ChainLink? = nil
        for idx in 0..<chain.count {
            let cur = chain[idx]
            if cur.type == .stop {
                if let ps = prevStop {
                    ps.nextStopSeconds = ps.end.seconds(between: cur.begin)
                    ps.nextStopMeters = Int(1000 * ps.end.distanceKm(between: cur.begin))
                }
                prevStop = cur
            }
        }
    }

    fileprivate func updateRecent(_ l: ChainLink) {
        if l.type != .stop {
            return
        }

        recentStops.append(l)
        while (l.begin.seconds(between: recentStops.first!.begin) > (10 * 60)) {
            recentStops.remove(at: 0)
        }

        l.recentStops = recentStops.count
        l.recentDistanceMeters = Int(1000 * l.begin.distanceKm(between: recentStops.first!.begin))
    }
}
*/