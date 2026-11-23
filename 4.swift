import Foundation
import CoreLocation
import MapKit

// MARK: - 基本資料模型

struct TrackPoint: Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
    let elevation: Double
}

struct Waypoint: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let elevation: Double?
}

struct ElevationSample: Identifiable {
    let id: Int
    let distanceKm: Double
    let elevation: Double
}

/// 錄製中的軌跡點
struct RecordedPoint {
    let coordinate: CLLocationCoordinate2D
    let elevation: Double
    let time: Date
}

/// 使用者位置投影到路線上的結果
struct RouteProjection {
    /// 距離路線最近線段的距離（公尺）
    let distanceToRoute: Double
    /// 沿路線已走距離（公尺）
    let distanceAlong: Double
    /// 投影點在路線上的海拔（公尺）
    let elevation: Double
    /// 沿路線累積爬升（公尺）
    let ascentSoFar: Double
}

// MARK: - 路線

struct GPXRoute {
    let name: String
    let points: [TrackPoint]
    let waypoints: [Waypoint]

    let coordinates: [CLLocationCoordinate2D]
    /// 每個軌跡點的累積距離（公尺）
    let cumulativeDistance: [Double]
    /// 每個軌跡點的累積爬升（公尺，已做雜訊過濾）
    let cumulativeAscent: [Double]
    let totalDistance: Double
    let totalAscent: Double
    let minElevation: Double
    let maxElevation: Double
    let samples: [ElevationSample]
    let region: MKCoordinateRegion

    /// 爬升雜訊門檻：海拔變化小於此值不計入
    private static let ascentThreshold = 3.0

    init(name: String, points: [TrackPoint], waypoints: [Waypoint]) {
        self.name = name
        self.points = points
        self.waypoints = waypoints
        self.coordinates = points.map { $0.coordinate }

        var cumDist: [Double] = [0]
        var cumAsc: [Double] = [0]
        var ascent = 0.0
        var refElevation = points[0].elevation

        cumDist.reserveCapacity(points.count)
        cumAsc.reserveCapacity(points.count)

        for i in 1..<points.count {
            let a = CLLocation(latitude: points[i - 1].coordinate.latitude,
                               longitude: points[i - 1].coordinate.longitude)
            let b = CLLocation(latitude: points[i].coordinate.latitude,
                               longitude: points[i].coordinate.longitude)
            cumDist.append(cumDist[i - 1] + a.distance(from: b))

            let e = points[i].elevation
            if e - refElevation >= Self.ascentThreshold {
                ascent += e - refElevation
                refElevation = e
            } else if refElevation - e >= Self.ascentThreshold {
                refElevation = e
            }
            cumAsc.append(ascent)
        }

        self.cumulativeDistance = cumDist
        self.cumulativeAscent = cumAsc
        self.totalDistance = cumDist.last ?? 0
        self.totalAscent = ascent

        let elevations = points.map { $0.elevation }
        self.minElevation = elevations.min() ?? 0
        self.maxElevation = elevations.max() ?? 0

        // 圖表降採樣（最多約 400 點）
        let step = max(1, points.count / 400)
        var s: [ElevationSample] = []
        var i = 0
        while i < points.count {
            s.append(ElevationSample(id: i, distanceKm: cumDist[i] / 1000, elevation: points[i].elevation))
            i += step
        }
        if let lastIndex = points.indices.last, s.last?.id != lastIndex {
            s.append(ElevationSample(id: lastIndex, distanceKm: cumDist[lastIndex] / 1000, elevation: points[lastIndex].elevation))
        }
        self.samples = s

        // 地圖範圍
        let lats = points.map { $0.coordinate.latitude }
        let lons = points.map { $0.coordinate.longitude }
        let minLat = lats.min() ?? 0, maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0, maxLon = lons.max() ?? 0
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                           longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * 1.35, 0.005),
                                   longitudeDelta: max((maxLon - minLon) * 1.35, 0.005))
        )
    }

    /// 將座標投影到路線上最近的線段（局部平面近似，山區尺度誤差可忽略）
    func project(_ c: CLLocationCoordinate2D) -> RouteProjection? {
        guard points.count >= 2 else { return nil }

        let mPerDegLat = 111_320.0
        let mPerDegLon = 111_320.0 * cos(c.latitude * .pi / 180)

        var bestDistance = Double.greatestFiniteMagnitude
        var bestIndex = 0
        var bestT = 0.0

        for i in 0..<(points.count - 1) {
            let p1 = points[i].coordinate
            let p2 = points[i + 1].coordinate

            let ax = (p1.longitude - c.longitude) * mPerDegLon
            let ay = (p1.latitude - c.latitude) * mPerDegLat
            let bx = (p2.longitude - c.longitude) * mPerDegLon
            let by = (p2.latitude - c.latitude) * mPerDegLat

            let dx = bx - ax
            let dy = by - ay
            let len2 = dx * dx + dy * dy

            var t = 0.0
            if len2 > 0 {
                t = ((-ax) * dx + (-ay) * dy) / len2
                t = min(max(t, 0), 1)
            }

            let px = ax + t * dx
            let py = ay + t * dy
            let d = (px * px + py * py).squareRoot()

            if d < bestDistance {
                bestDistance = d
                bestIndex = i
                bestT = t
            }
        }

        let segLength = cumulativeDistance[bestIndex + 1] - cumulativeDistance[bestIndex]
        let along = cumulativeDistance[bestIndex] + bestT * segLength
        let elevation = points[bestIndex].elevation
            + bestT * (points[bestIndex + 1].elevation - points[bestIndex].elevation)
        let ascent = cumulativeAscent[bestIndex]
            + bestT * (cumulativeAscent[bestIndex + 1] - cumulativeAscent[bestIndex])

        return RouteProjection(distanceToRoute: bestDistance,
                               distanceAlong: along,
                               elevation: elevation,
                               ascentSoFar: ascent)
    }
}
