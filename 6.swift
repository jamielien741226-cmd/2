import Foundation
import CoreLocation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isRecording = false
    @Published var recordedPoints: [RecordedPoint] = []
    @Published var recordedDistance: Double = 0

    private let manager = CLLocationManager()
    private var lastRecorded: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 3
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
        manager.headingFilter = 5
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - 一般定位

    func start() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        beginUpdatesIfAuthorized()
    }

    private func beginUpdatesIfAuthorized() {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        default:
            break
        }
    }

    // MARK: - 錄製

    func startRecording() {
        recordedPoints = []
        recordedDistance = 0
        lastRecorded = nil
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
        isRecording = true
    }

    /// 結束錄製並輸出 GPX；點數不足時回傳 nil
    func stopRecording() -> URL? {
        isRecording = false
        manager.allowsBackgroundLocationUpdates = false
        manager.showsBackgroundLocationIndicator = false

        guard recordedPoints.count >= 2 else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd_HHmm"
        let stamp = formatter.string(from: recordedPoints[0].time)
        let name = "Baiyue_\(stamp)"

        let gpx = GPXWriter.makeGPX(name: name, points: recordedPoints)

        do {
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Recordings", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let url = dir.appendingPathComponent("\(name).gpx")
            try gpx.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        beginUpdatesIfAuthorized()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for loc in locations {
            guard loc.horizontalAccuracy >= 0 else { continue }
            location = loc

            if isRecording && loc.horizontalAccuracy <= 30 {
                if let last = lastRecorded {
                    let d = loc.distance(from: last)
                    if d < 2 { continue }   // 過濾原地漂移
                    recordedDistance += d
                }
                lastRecorded = loc
                recordedPoints.append(RecordedPoint(coordinate: loc.coordinate,
                                                    elevation: loc.altitude,
                                                    time: loc.timestamp))
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // locationUnknown 等暫時性錯誤無需處理，系統會持續嘗試
    }
}

// MARK: - GPX 輸出

enum GPXWriter {
    static func makeGPX(name: String, points: [RecordedPoint]) -> String {
        let iso = ISO8601DateFormatter()
        let safeName = escape(name)

        var s = ""
        s += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        s += "<gpx version=\"1.1\" creator=\"BaiyueNav\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n"
        s += "  <metadata>\n"
        s += "    <name>\(safeName)</name>\n"
        if let first = points.first {
            s += "    <time>\(iso.string(from: first.time))</time>\n"
        }
        s += "  </metadata>\n"
        s += "  <trk>\n"
        s += "    <name>\(safeName)</name>\n"
        s += "    <trkseg>\n"

        for p in points {
            let lat = String(format: "%.7f", p.coordinate.latitude)
            let lon = String(format: "%.7f", p.coordinate.longitude)
            let ele = String(format: "%.1f", p.elevation)
            let time = iso.string(from: p.time)
            s += "      <trkpt lat=\"\(lat)\" lon=\"\(lon)\">\n"
            s += "        <ele>\(ele)</ele>\n"
            s += "        <time>\(time)</time>\n"
            s += "      </trkpt>\n"
        }

        s += "    </trkseg>\n"
        s += "  </trk>\n"
        s += "</gpx>\n"
        return s
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
