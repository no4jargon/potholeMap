import Foundation

struct RecordingSample: Identifiable {
    let id = UUID()
    let timestamp: Double
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let speed: Double
    let accelX: Double
    let accelY: Double
    let accelZ: Double
    let gyroX: Double
    let gyroY: Double
    let gyroZ: Double
    let gravityX: Double
    let gravityY: Double
    let gravityZ: Double
}

enum RecordingDataLoader {
    static func loadSamples(from url: URL) -> [RecordingSample] {
        guard let data = try? String(contentsOf: url) else { return [] }
        let lines = data.split(separator: "\n")
        guard lines.count > 1 else { return [] }
        return lines.dropFirst().compactMap { line in
            let components = line.split(separator: ",")
            guard components.count >= 14 else { return nil }
            return RecordingSample(
                timestamp: Double(components[0]) ?? 0,
                latitude: Double(components[1]) ?? 0,
                longitude: Double(components[2]) ?? 0,
                altitude: Double(components[3]) ?? 0,
                speed: Double(components[4]) ?? 0,
                accelX: Double(components[5]) ?? 0,
                accelY: Double(components[6]) ?? 0,
                accelZ: Double(components[7]) ?? 0,
                gyroX: Double(components[8]) ?? 0,
                gyroY: Double(components[9]) ?? 0,
                gyroZ: Double(components[10]) ?? 0,
                gravityX: Double(components[11]) ?? 0,
                gravityY: Double(components[12]) ?? 0,
                gravityZ: Double(components[13]) ?? 0
            )
        }
    }
}
