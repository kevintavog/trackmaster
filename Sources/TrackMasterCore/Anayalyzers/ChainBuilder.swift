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
    public var count = 1

    public var nextSeconds: Double = 0
    public var nextMeters: Int = 0

    public init(begin: GpsPoint, end: GpsPoint, type: ChainLinkType, instance: Any) {
        self.begin = begin
        self.end = end
        self.type = type
        self.instance = instance
    }

    public var description: String {
        return "\(type) \(begin.time), next: \(nextMeters) m, \(nextSeconds) s, count=\(count); \(instance)"
    }

    public func add(link: ChainLink) {
        if link.end.time > end.time {
            end = link.end
            nextSeconds += link.nextSeconds
            nextMeters += link.nextMeters
            count += link.count
        }
        if link.end.time < begin.time {
print("new end earlier than my begin!!!")
        }
    }
}

public class Chain {

    static public func toRuns(chain: [ChainLink]) -> ([GpsRun]) {
        return chain.filter { $0.type == .run }.map { $0.instance as! GpsRun }
    }

    static public func toStops(chain: [ChainLink]) -> ([GpsPoint]) {
        return chain.filter { $0.type == .stop }.map { $0.instance as! GpsPoint }
    }

    /*  Create a simple chain of stops & runs, in time order.
        Distance and time offsets (meters & seconds) are calculated between consecutive items.
        Items are consoldated by type and likely bad runs are removed.
     */
    static public func build(stops: [GpsPoint], runs: [GpsRun]) -> ([ChainLink],[ChainLink]) {
        if stops.count == 0 && runs.count == 0 {
            return ([ChainLink](), [ChainLink]())
        }

        let ordered = orderByTime(stops, runs)
        calculateOffsets(ordered)
        return removeBadRuns(consolidate(ordered))
    }

    static public func removeBadRuns(_ chain: [ChainLink]) -> ([ChainLink],[ChainLink]) {
        var removedLinks = [ChainLink]()
        var filtered = [ChainLink]()
        var prevStop: ChainLink? = nil
        var previousLink: ChainLink? = nil
        for c in chain {
            if c.type == .run {
                if let ps = prevStop {
                    var prevScore = 0
                    prevScore += ps.count >= 3 ? 1 : 0
                    prevScore += ps.nextSeconds >= 120 ? 1 : 0
                    prevScore += ps.nextMeters >= 20 ? 1 : 0
                    var nextScore = c.nextSeconds >= 15 ? 1 : 0
                    nextScore += c.nextMeters >= 15 ? 1 : 0

                    // Remove this run, combining it with the previous stop
                    if prevScore >= 3 && nextScore >= 1 {
                        removedLinks.append(c)
                        ps.add(link: c)
                        continue
                    }
                }
            } else {
                // Combine consecutive stops, which will exist if a run was removed
                if prevStop != nil && previousLink != nil && previousLink!.type == .stop {
                    prevStop!.add(link: c)
                } else {
                    prevStop = c
                }
            }
            if previousLink == nil || (previousLink != nil && previousLink!.type != c.type) {
                filtered.append(c)
            }
            previousLink = c
        }

        return (filtered, removedLinks)
    }

    static fileprivate func consolidate(_ original: [ChainLink]) -> [ChainLink] {
        var chain = [ChainLink]()
        var prevLink = original[0]
        for l in original {
            if l.type == prevLink.type {
                prevLink.add(link: l)
            } else {
                chain.append(prevLink)
                prevLink = l
            }
        }
        if prevLink.begin.time != chain.last!.begin.time {
            chain.append(prevLink)
        }

        return chain
    }

    static fileprivate func orderByTime(_ stops: [GpsPoint], _ runs: [GpsRun]) -> [ChainLink] {
        var chain = [ChainLink]()
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
                beginPoint = stops[stopIndex]
                endPoint = beginPoint
                instance = stops[stopIndex]
                stopIndex += 1
            } else {
                let r = runs[runIndex]
                let s = stops[stopIndex]
                if r.points.first!.time < s.time {
                    type = .run
                    beginPoint = r.points.first!
                    endPoint = r.points.last!
                    instance = r
                    runIndex += 1
                } else {
                    type = .stop
                    beginPoint = s
                    endPoint = beginPoint
                    instance = s
                    stopIndex += 1
                }
            }

            chain.append(ChainLink(begin: beginPoint!, end: endPoint!, type: type, instance: instance!))
        }

        return chain
    }

    static fileprivate func calculateOffsets(_ chain: [ChainLink]) {
        for idx in 0..<chain.count-1 {
            let cur = chain[idx]
            let next = chain[idx + 1]
            cur.nextSeconds = cur.end.seconds(between: next.begin)
            cur.nextMeters = Int(1000 * cur.end.distanceKm(between: next.begin))
        }
    }
}