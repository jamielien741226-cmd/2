import SwiftUI
import Charts

struct ElevationChartView: View {
    let route: GPXRoute
    let progress: RouteProjection?

    private var lowerBound: Double {
        floor((route.minElevation - 20) / 10) * 10
    }

    private var upperBound: Double {
        let hi = ceil((route.maxElevation + 20) / 10) * 10
        return max(hi, lowerBound + 50)
    }

    var body: some View {
        Chart {
            ForEach(route.samples) { s in
                AreaMark(
                    x: .value("距離", s.distanceKm),
                    yStart: .value("基準", lowerBound),
                    yEnd: .value("海拔", s.elevation)
                )
                .foregroundStyle(
                    LinearGradient(colors: [Color.blue.opacity(0.35), Color.blue.opacity(0.03)],
                                   startPoint: .top, endPoint: .bottom)
                )
            }

            ForEach(route.samples) { s in
                LineMark(
                    x: .value("距離", s.distanceKm),
                    y: .value("海拔", s.elevation)
                )
                .foregroundStyle(Color.blue)
                .interpolationMethod(.monotone)
            }

            if let p = progress {
                RuleMark(x: .value("目前位置", p.distanceAlong / 1000))
                    .foregroundStyle(Color.orange.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

                PointMark(
                    x: .value("目前位置", p.distanceAlong / 1000),
                    y: .value("目前海拔", p.elevation)
                )
                .symbolSize(180)
                .foregroundStyle(Color.red)
                .annotation(position: .top, spacing: 4) {
                    Text("\(Int(p.elevation.rounded())) m")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
        .chartYScale(domain: lowerBound...upperBound)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(String(format: "%.1f km", d))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text("\(Int(d))")
                    }
                }
            }
        }
    }
}
