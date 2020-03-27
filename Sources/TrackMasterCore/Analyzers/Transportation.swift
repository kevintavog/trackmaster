import Foundation

// From https://www.bbc.com/education/guides/zq4mfcw/revision
// Average speeds   m/s     km/h        m/h
//      --          0.417   1.5         0.93
//      Walking     1.5     5.4         3.4
//      Running     5       18          11
//      Cycling     7       25          15
//      Car         13-30   46-108      29-67
//      Train       56      201         125
//      Plane       250     900         560

// Speeds, in kilometers per hour, of different transportation types. Given a single speed, a table of SpeedProfile instances
// is used to determine the two most likely transportation types.
// Probabilities are 1.0 for included in the nominal range. Outside of that range, but within the absolute range, the
// probability is a linear value starting from 0.10
struct SpeedProfile {
    let absoluteMinimum: Double
    let nominalMinimum: Double
    let nominalMaximum: Double
    let absoluteMaximum: Double
    let mode: TransportationMode
}

public class Transportation {

    static private let speedProfiles = [
        SpeedProfile(absoluteMinimum: 0.0, nominalMinimum: 1.0, nominalMaximum: 6.4, absoluteMaximum: 7.4, mode: .foot),
        SpeedProfile(absoluteMinimum: 6.4, nominalMinimum: 12.0, nominalMaximum: 34.0, absoluteMaximum: 41.0, mode: .bicycle),
        SpeedProfile(absoluteMinimum: 16.0, nominalMinimum: 25.0, nominalMaximum: 128.0, absoluteMaximum: 160.0, mode: .car),
        SpeedProfile(absoluteMinimum: 90.0, nominalMinimum: 100.0, nominalMaximum: 300.0, absoluteMaximum: 350.0, mode: .train),
        SpeedProfile(absoluteMinimum: 100.0, nominalMinimum: 160.0, nominalMaximum: 800.0, absoluteMaximum: 1000.0, mode: .plane)]

    static public func calculate(pt: GpsPoint) -> [TransportationType] {
        return calculate(speedKmh: pt.calculatedSpeedKmh)
    }

    static public func calculate(speedKmh: Double) -> [TransportationType] {
        var types = [TransportationType]()
        for p in speedProfiles {
            var probability: Double? = nil
            if speedKmh >= p.nominalMinimum && speedKmh <= p.nominalMaximum {
                probability = 1.0
            } else if speedKmh >= p.absoluteMinimum && speedKmh < p.nominalMinimum {
                probability = Transportation.probability(speedKmh, p.absoluteMinimum, p.nominalMinimum)
            } else if speedKmh > p.nominalMaximum && speedKmh <= p.absoluteMaximum {
                probability = Transportation.probability(speedKmh, p.absoluteMaximum, p.nominalMaximum)
            }

            if let probability = probability, probability > 0.0 {
                types.append(TransportationType(probability: probability, mode: p.mode))                
            }
        }

        if types.count < 1 {
            return [TransportationType(probability: 1.0, mode: .unknown)]
        }
        return Array(types.sorted(by: { $0.probability > $1.probability}).prefix(2))
    }

    static private func probability(_ value: Double, _ absolute: Double, _ nominal: Double) -> Double {
        return max(0.01, (value - absolute) / (nominal - absolute))
    }
}
