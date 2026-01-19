import Combine
import Foundation

final class RecordingManager: ObservableObject {
    @Published private(set) var recordings: [Recording] = []
    @Published private(set) var analyses: [UUID: RecordingAnalysis] = [:]
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
            let title = RecordingFileStore.defaultTitle(index: RecordingFileStore.nextIndex(from: recordings))
            let recording = Recording(
                id: UUID(),
                title: title,
                date: startDate ?? finishDate,
                duration: duration,
                fileURL: fileURL
            )
            recordings.insert(recording, at: 0)
            RecordingFileStore.saveTitle(title, for: fileURL)
        }
    }

    func loadRecordings() {
        recordings = RecordingFileStore.loadRecordings()
    }

    func renameRecording(_ recording: Recording, to newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = recordings.firstIndex(where: { $0.id == recording.id }) else {
            return
        }
        recordings[index] = Recording(
            id: recording.id,
            title: trimmed,
            date: recording.date,
            duration: recording.duration,
            fileURL: recording.fileURL
        )
        RecordingFileStore.saveTitle(trimmed, for: recording.fileURL)
    }

    func deleteRecording(_ recording: Recording) {
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings.remove(at: index)
        }
        analyses[recording.id] = nil
        RecordingFileStore.deleteTitle(for: recording.fileURL)
        try? FileManager.default.removeItem(at: recording.fileURL)
    }

    func analyzeRecording(_ recording: Recording) {
        let samples = RecordingDataLoader.loadSamples(from: recording.fileURL)
        guard let analysis = RecordingAnalyzer.analyze(samples: samples) else { return }
        analyses[recording.id] = analysis
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
    private static let titlesKey = "recordingTitles"
    private static let defaultTitlePrefix = "Road Recording "

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

    static func defaultTitle(index: Int) -> String {
        "Road Recording \(index)"
    }

    static func nextIndex(from recordings: [Recording]) -> Int {
        let maxIndex = recordings.compactMap { defaultTitleIndex(from: $0.title) }.max() ?? 0
        return maxIndex + 1
    }

    private static func defaultTitleIndex(from title: String) -> Int? {
        guard title.hasPrefix(defaultTitlePrefix) else { return nil }
        let suffix = title.dropFirst(defaultTitlePrefix.count)
        return Int(suffix)
    }

    static func loadRecordings() -> [Recording] {
        let folder = documentsDirectory()
        guard let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.creationDateKey]) else {
            return []
        }

        let data = files
            .filter { $0.pathExtension == "csv" }
            .compactMap { fileURL -> Recording? in
                let values = try? fileURL.resourceValues(forKeys: [.creationDateKey])
                let date = values?.creationDate ?? Date()
                let duration = DurationEstimator.estimateDuration(for: fileURL)
                return Recording(
                    id: UUID(),
                    title: "",
                    date: date,
                    duration: duration,
                    fileURL: fileURL
                )
            }
            .sorted(by: { $0.date > $1.date })

        var titles = loadTitles()
        var didUpdateTitles = false

        let recordings = data.enumerated().map { index, recording in
            let fileKey = recording.fileURL.lastPathComponent
            let title = titles[fileKey] ?? defaultTitle(index: index + 1)
            if titles[fileKey] == nil {
                titles[fileKey] = title
                didUpdateTitles = true
            }
            return Recording(
                id: recording.id,
                title: title,
                date: recording.date,
                duration: recording.duration,
                fileURL: recording.fileURL
            )
        }

        if didUpdateTitles {
            saveTitles(titles)
        }

        return recordings
    }

    static func title(for fileURL: URL) -> String? {
        loadTitles()[fileURL.lastPathComponent]
    }

    static func saveTitle(_ title: String, for fileURL: URL) {
        var titles = loadTitles()
        titles[fileURL.lastPathComponent] = title
        saveTitles(titles)
    }

    static func deleteTitle(for fileURL: URL) {
        var titles = loadTitles()
        titles.removeValue(forKey: fileURL.lastPathComponent)
        saveTitles(titles)
    }

    private static func loadTitles() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: titlesKey) as? [String: String] ?? [:]
    }

    private static func saveTitles(_ titles: [String: String]) {
        UserDefaults.standard.set(titles, forKey: titlesKey)
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
