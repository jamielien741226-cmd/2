import SwiftUI
import MapKit
import UniformTypeIdentifiers
import UIKit

enum MapMode: String, CaseIterable, Identifiable {
    case standard = "標準"
    case hybrid = "衛星混合"
    var id: String { rawValue }
}

struct ContentView: View {

    private let offRouteThreshold = 40.0      // 公尺
    private let offRouteRecover = 35.0        // 回到此距離內才解除警告（避免邊界閃爍）

    @StateObject private var lm = LocationManager()

    @State private var route: GPXRoute?
    @State private var progress: RouteProjection?
    @State private var isOffRoute = false
    @State private var lastHaptic = Date.distantPast

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var mapMode: MapMode = .hybrid
    @State private var showChart = true

    @State private var showImporter = false
    @State private var importError: String?

    @State private var exportURL: URL?
    @State private var showExportSheet = false
    @State private var recordError: String?

    private let haptic = UIImpactFeedbackGenerator(style: .heavy)

    // MARK: - Body

    var body: some View {
        ZStack {
            mapView

            VStack(spacing: 8) {
                if isOffRoute, let d = progress?.distanceToRoute {
                    offRouteBanner(distance: d)
                }
                topBar
                Spacer()
                HStack {
                    Spacer()
                    sideButtons
                }
                .padding(.horizontal, 10)
                bottomPanel
            }
        }
        .onAppear {
            lm.start()
            if route == nil, let data = GPXStore.load(),
               let r = try? GPXParser.parse(data: data, fallbackName: "上次匯入路線") {
                route = r
                position = .region(r.region)
                updateNavigation()
            }
        }
        .onChange(of: lm.location) { _, _ in
            updateNavigation()
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: importTypes,
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("匯入失敗", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
        .alert("無法匯出", isPresented: Binding(
            get: { recordError != nil },
            set: { if !$0 { recordError = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(recordError ?? "")
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ExportSheet(url: url)
            }
        }
    }

    // MARK: - 地圖

    private var mapView: some View {
        Map(position: $position) {
            UserAnnotation()

            if let route {
                MapPolyline(coordinates: route.coordinates)
                    .stroke(.blue, lineWidth: 5)

                ForEach(route.waypoints) { wp in
                    Annotation(wp.name, coordinate: wp.coordinate) {
                        Image(systemName: "flag.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .red)
                    }
                }
            }

            if lm.isRecording && lm.recordedPoints.count >= 2 {
                MapPolyline(coordinates: lm.recordedPoints.map { $0.coordinate })
                    .stroke(.orange, lineWidth: 3)
            }
        }
        .mapStyle(currentMapStyle)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea()
    }

    private var currentMapStyle: MapStyle {
        switch mapMode {
        case .standard: return .standard(elevation: .realistic)
        case .hybrid: return .hybrid(elevation: .realistic)
        }
    }

    // MARK: - 上方 UI

    private func offRouteBanner(distance: Double) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("偏離路線 \(Int(distance.rounded())) m！請確認方向")
                .fontWeight(.bold)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.red)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                showImporter = true
            } label: {
                Label("匯入 GPX", systemImage: "square.and.arrow.down")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)

            Spacer()

            Picker("地圖", selection: $mapMode) {
                ForEach(MapMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 190)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 10)
    }

    private var sideButtons: some View {
        VStack(spacing: 10) {
            circleButton(systemName: "location.fill") {
                position = .userLocation(followsHeading: true, fallback: .automatic)
            }
            if let route {
                circleButton(systemName: "map") {
                    position = .region(route.region)
                }
                circleButton(systemName: "chart.xyaxis.line") {
                    withAnimation { showChart.toggle() }
                }
            }
        }
    }

    private func circleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 下方面板

    private var bottomPanel: some View {
        VStack(spacing: 10) {
            if let route {
                HStack {
                    Text(route.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Text(String(format: "全長 %.2f km · 總爬升 %d m",
                                route.totalDistance / 1000,
                                Int(route.totalAscent.rounded())))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("尚未匯入路線，請點選「匯入 GPX」")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            dashboard

            if let route, showChart {
                ElevationChartView(route: route, progress: progress)
                    .frame(height: 130)
            }

            if lm.authorizationStatus == .denied || lm.authorizationStatus == .restricted {
                Text("定位權限被關閉，請到「設定 > 隱私權 > 定位服務」開啟。")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            recordingBar
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    private var dashboard: some View {
        HStack(spacing: 0) {
            MetricView(title: "目前海拔", value: altitudeText, unit: "m")
            Divider().frame(height: 36)
            MetricView(title: "已走距離", value: distanceText, unit: "km")
            Divider().frame(height: 36)
            MetricView(title: "已爬 / 總爬升", value: ascentText, unit: "m")
            Divider().frame(height: 36)
            MetricView(title: "距離路線", value: offsetText, unit: "m", highlight: isOffRoute)
        }
    }

    private var recordingBar: some View {
        HStack(spacing: 10) {
            if lm.isRecording {
                VStack(alignment: .leading, spacing: 2) {
                    Label("錄製中", systemImage: "record.circle")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.red)
                    Text(String(format: "%.2f km · %d 點", lm.recordedDistance / 1000, lm.recordedPoints.count))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    finishRecording()
                } label: {
                    Label("結束並匯出 GPX", systemImage: "stop.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                if let url = exportURL {
                    ShareLink(item: url, preview: SharePreview(url.lastPathComponent)) {
                        Label("分享上次錄製", systemImage: "square.and.arrow.up")
                            .font(.footnote)
                    }
                }
                Spacer()
                Button {
                    lm.startRecording()
                } label: {
                    Label("開始紀錄", systemImage: "record.circle")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
    }

    // MARK: - 顯示文字

    private var altitudeText: String {
        guard let loc = lm.location, loc.verticalAccuracy >= 0 else { return "—" }
        return "\(Int(loc.altitude.rounded()))"
    }

    private var distanceText: String {
        guard let p = progress else { return "—" }
        return String(format: "%.2f", p.distanceAlong / 1000)
    }

    private var ascentText: String {
        guard let route, let p = progress else { return "—" }
        return "\(Int(p.ascentSoFar.rounded()))/\(Int(route.totalAscent.rounded()))"
    }

    private var offsetText: String {
        guard let p = progress else { return "—" }
        return "\(Int(p.distanceToRoute.rounded()))"
    }

    // MARK: - 邏輯

    private var importTypes: [UTType] {
        // 系統不一定登錄 .gpx 型別，因此加入 .xml 與 .data 當後備，確保檔案可選取
        [UTType(filenameExtension: "gpx"), .xml, .data].compactMap { $0 }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            importError = error.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                let parsed = try GPXParser.parse(
                    data: data,
                    fallbackName: url.deletingPathExtension().lastPathComponent
                )
                GPXStore.save(data)
                route = parsed
                isOffRoute = false
                position = .region(parsed.region)
                updateNavigation()
            } catch {
                importError = error.localizedDescription
            }
        }
    }

    private func updateNavigation() {
        guard let route else {
            progress = nil
            isOffRoute = false
            return
        }
        // 定位精度太差時不更新，避免誤報偏離
        guard let loc = lm.location,
              loc.horizontalAccuracy >= 0,
              loc.horizontalAccuracy <= 50,
              let p = route.project(loc.coordinate) else { return }

        progress = p

        let off: Bool
        if isOffRoute {
            off = p.distanceToRoute > offRouteRecover
        } else {
            off = p.distanceToRoute > offRouteThreshold
        }

        withAnimation { isOffRoute = off }

        if off && Date().timeIntervalSince(lastHaptic) > 8 {
            haptic.prepare()
            haptic.impactOccurred()
            lastHaptic = Date()
        }
    }

    private func finishRecording() {
        if let url = lm.stopRecording() {
            exportURL = url
            showExportSheet = true
        } else {
            recordError = "錄製的軌跡點不足（至少需要 2 個點），未產生檔案。"
        }
    }
}

// MARK: - 子元件

private struct MetricView: View {
    let title: String
    let value: String
    let unit: String
    var highlight: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.headline, design: .rounded).monospacedDigit())
                .foregroundStyle(highlight ? Color.red : Color.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ExportSheet: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
            Text("軌跡已儲存")
                .font(.headline)
            Text(url.lastPathComponent)
                .font(.footnote)
                .foregroundStyle(.secondary)

            ShareLink(item: url, preview: SharePreview(url.lastPathComponent)) {
                Label("分享 / 儲存 GPX 檔", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button("完成") { dismiss() }
        }
        .padding(24)
        .presentationDetents([.height(320)])
    }
}
