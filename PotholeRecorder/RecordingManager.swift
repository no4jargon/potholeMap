import Combine
import Foundation

final class RecordingManager: ObservableObject {
    @Published private(set) var recordings: [Recording] = []
    @Published private(set) var isRecording = false
    @Published private(set) var elapsedTimeString = "00:00"

    private var recorder = MotionLocationRecorder()
    private var timerCancellable: AnyCancellable?
    private var startDate: Date?

    func startRecording() {
        guard !isRecording else { return }
        startDate = Date()
        elapsedTimeString = "00:00"
        isRecording = true
        recorder.start()
        startTimer()
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        timerCancellable?.cancel()
        let finishDate = Date()
        let duration = finishDate.timeIntervalSince(startDate ?? finishDate)
        if let fileURL = recorder.stop() {
            let recording = Recording(
                id: UUID(),
                title: recorder.title,
                date: startDate ?? finishDate,
                duration: duration,
                fileURL: fileURL
            )
            recordings.insert(recording, at: 0)
        }
    }

    func loadRecordings() {
        recordings = RecordingFileStore.loadRecordings()
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateElapsedTime()
            }
    }

    private func updateElapsedTime() {
        guard let startDate else { return }
        let elapsed = Date().timeIntervalSince(startDate)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        elapsedTimeString = String(format: "%02d:%02d", minutes, seconds)
    }
}

enum RecordingFileStore {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()

    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func makeRecordingURL() -> URL {
        let timestamp = dateFormatter.string(from: Date())
        return documentsDirectory().appendingPathComponent("pothole_\(timestamp).csv")
    }

    static func loadRecordings() -> [Recording] {
        let folder = documentsDirectory()
        guard let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.creationDateKey]) else {
            return []
        }

        return files
            .filter { $0.pathExtension == "csv" }
            .compactMap { fileURL -> Recording? in
                let values = try? fileURL.resourceValues(forKeys: [.creationDateKey])
                let date = values?.creationDate ?? Date()
                let duration = DurationEstimator.estimateDuration(for: fileURL)
                return Recording(
                    id: UUID(),
                    title: "Pothole Recording",
                    date: date,
                    duration: duration,
                    fileURL: fileURL
                )
            }
            .sorted(by: { $0.date > $1.date })
    }
}

enum DurationEstimator {
    static func estimateDuration(for url: URL) -> TimeInterval {
        guard let data = try? String(contentsOf: url) else { return 0 }
        let lines = data.split(separator: "\n")
        guard lines.count > 1 else { return 0 }
        let timestamps = lines.dropFirst().compactMap { line -> Double? in
            let components = line.split(separator: ",")
            return Double(components.first ?? "")
        }
        guard let first = timestamps.first, let last = timestamps.last else { return 0 }
        return last - first
    }
}
