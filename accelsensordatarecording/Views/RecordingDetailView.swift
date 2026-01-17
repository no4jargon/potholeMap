import SwiftUI

struct RecordingDetailView: View {
    let recording: Recording

    @State private var samples: [RecordingSample] = []
    @State private var selectedTab: DataTab = .gpsAccel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                header

                dataTabs

                dataContent
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            samples = RecordingDataLoader.loadSamples(from: recording.fileURL)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recording.title)
                .font(.title.bold())
                .foregroundColor(.white)
            Text("\(recording.subtitle) · \(recording.durationString)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            Text("Tap a tab to inspect synced GPS + accelerometer rows. Map view is coming next.")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dataTabs: some View {
        Picker("Data View", selection: $selectedTab) {
            ForEach(DataTab.allCases, id: \.self) { tab in
                Text(tab.title)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var dataContent: some View {
        if samples.isEmpty {
            Spacer()
            Text("No samples available yet. Record a run to see synced data.")
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        } else {
            List {
                Section(header: sectionHeader) {
                    ForEach(samples) { sample in
                        switch selectedTab {
                        case .gpsAccel:
                            gpsAccelRow(for: sample)
                        case .allSensors:
                            allSensorsRow(for: sample)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private var sectionHeader: some View {
        HStack {
            Text("Time")
            Spacer()
            Text(selectedTab == .gpsAccel ? "GPS + Accel" : "All Sensors")
        }
        .font(.caption)
        .foregroundColor(.white.opacity(0.6))
        .textCase(nil)
    }

    private func gpsAccelRow(for sample: RecordingSample) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(formattedTimestamp(for: sample))
                .font(.caption.monospacedDigit())
                .foregroundColor(.white.opacity(0.7))
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "lat %.5f, lon %.5f", sample.latitude, sample.longitude))
                Text(String(format: "accel x %.3f y %.3f z %.3f", sample.accelX, sample.accelY, sample.accelZ))
                    .foregroundColor(.white.opacity(0.8))
            }
            .font(.caption.monospacedDigit())
            Spacer(minLength: 0)
        }
        .listRowBackground(Color.black)
        .foregroundColor(.white)
    }

    private func allSensorsRow(for sample: RecordingSample) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formattedTimestamp(for: sample))
                .font(.caption.monospacedDigit())
                .foregroundColor(.white.opacity(0.7))
            Text(String(format: "gps %.5f, %.5f alt %.1f spd %.2f", sample.latitude, sample.longitude, sample.altitude, sample.speed))
            Text(String(format: "accel %.3f %.3f %.3f", sample.accelX, sample.accelY, sample.accelZ))
                .foregroundColor(.white.opacity(0.8))
            Text(String(format: "gyro %.3f %.3f %.3f", sample.gyroX, sample.gyroY, sample.gyroZ))
                .foregroundColor(.white.opacity(0.8))
            Text(String(format: "gravity %.3f %.3f %.3f", sample.gravityX, sample.gravityY, sample.gravityZ))
                .foregroundColor(.white.opacity(0.8))
        }
        .font(.caption.monospacedDigit())
        .foregroundColor(.white)
        .listRowBackground(Color.black)
    }

    private func formattedTimestamp(for sample: RecordingSample) -> String {
        guard let first = samples.first?.timestamp else { return "--" }
        let offset = sample.timestamp - first
        return String(format: "+%.2fs", offset)
    }
}

private enum DataTab: CaseIterable {
    case gpsAccel
    case allSensors

    var title: String {
        switch self {
        case .gpsAccel:
            return "GPS + Accel"
        case .allSensors:
            return "All Sensors"
        }
    }
}

#Preview {
    NavigationStack {
        RecordingDetailView(recording: Recording(
            id: UUID(),
            title: "Pothole Recording",
            date: Date(),
            duration: 42,
            fileURL: URL(fileURLWithPath: "/tmp/sample.csv")
        ))
    }
}
