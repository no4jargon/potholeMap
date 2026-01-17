import Foundation

struct Recording: Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let duration: TimeInterval
    let fileURL: URL

    var subtitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var durationString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
