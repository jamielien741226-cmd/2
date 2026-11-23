import Foundation
import CoreLocation

enum GPXError: LocalizedError {
    case invalidXML(String)
    case noTrackPoints

    var errorDescription: String? {
        switch self {
        case .invalidXML(let msg): return "GPX 檔案格式錯誤：\(msg)"
        case .noTrackPoints: return "檔案中找不到足夠的軌跡點（至少需要 2 個 <trkpt>）。"
        }
    }
}

final class GPXParser: NSObject, XMLParserDelegate {

    private var points: [TrackPoint] = []
    private var waypoints: [Waypoint] = []
    private var routeName = ""

    private var inTrackPoint = false
    private var inWaypoint = false
    private var currentLat = 0.0
    private var currentLon = 0.0
    private var currentEle: Double?
    private var currentName = ""
    private var buffer = ""
    private var lastElevation = 0.0

    static func parse(data: Data, fallbackName: String = "未命名路線") throws -> GPXRoute {
        let delegate = GPXParser()
        let xml = XMLParser(data: data)
        xml.delegate = delegate
        guard xml.parse() else {
            throw GPXError.invalidXML(xml.parserError?.localizedDescription ?? "未知錯誤")
        }
        guard delegate.points.count >= 2 else { throw GPXError.noTrackPoints }
        return GPXRoute(name: delegate.routeName.isEmpty ? fallbackName : delegate.routeName,
                        points: delegate.points,
                        waypoints: delegate.waypoints)
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        buffer = ""
        switch elementName {
        case "trkpt", "rtept":
            if let (lat, lon) = Self.latLon(from: attributeDict) {
                inTrackPoint = true
                currentLat = lat
                currentLon = lon
                currentEle = nil
            }
        case "wpt":
            if let (lat, lon) = Self.latLon(from: attributeDict) {
                inWaypoint = true
                currentLat = lat
                currentLon = lon
                currentEle = nil
                currentName = ""
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        let text = buffer.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "ele":
            if inTrackPoint || inWaypoint, let v = Double(text) {
                currentEle = v
            }
        case "name":
            if inWaypoint {
                currentName = text
            } else if !inTrackPoint && routeName.isEmpty && !text.isEmpty {
                routeName = text
            }
        case "trkpt", "rtept":
            if inTrackPoint {
                let ele = currentEle ?? lastElevation
                lastElevation = ele
                points.append(TrackPoint(id: points.count,
                                         coordinate: CLLocationCoordinate2D(latitude: currentLat, longitude: currentLon),
                                         elevation: ele))
                inTrackPoint = false
            }
        case "wpt":
            if inWaypoint {
                waypoints.append(Waypoint(name: currentName.isEmpty ? "航點" : currentName,
                                          coordinate: CLLocationCoordinate2D(latitude: currentLat, longitude: currentLon),
                                          elevation: currentEle))
                inWaypoint = false
            }
        default:
            break
        }
        buffer = ""
    }

    private static func latLon(from attributes: [String: String]) -> (Double, Double)? {
        guard let latStr = attributes["lat"], let lonStr = attributes["lon"],
              let lat = Double(latStr), let lon = Double(lonStr),
              (-90.0...90.0).contains(lat), (-180.0...180.0).contains(lon) else { return nil }
        return (lat, lon)
    }
}

// MARK: - 上次匯入路線的本地快取（重開 App 不必重新匯入）

enum GPXStore {
    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("last_route.gpx")
    }

    static func save(_ data: Data) {
        try? data.write(to: fileURL, options: .atomic)
    }

    static func load() -> Data? {
        try? Data(contentsOf: fileURL)
    }
}
