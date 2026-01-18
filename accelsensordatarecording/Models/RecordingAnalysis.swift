import Foundation
import simd

struct RecordingAnalysis {
    let planeNormal: SIMD3<Double>
    let perpendicularAcceleration: [Double]
}

enum RecordingAnalyzer {
    static func analyze(samples: [RecordingSample]) -> RecordingAnalysis? {
        guard !samples.isEmpty else { return nil }
        let vectors = samples.map { SIMD3<Double>($0.accelX, $0.accelY, $0.accelZ) }
        let mean = vectors.reduce(SIMD3<Double>(repeating: 0)) { $0 + $1 } / Double(vectors.count)

        var covariance = Array(repeating: Array(repeating: 0.0, count: 3), count: 3)
        for vector in vectors {
            let centered = vector - mean
            covariance[0][0] += centered.x * centered.x
            covariance[0][1] += centered.x * centered.y
            covariance[0][2] += centered.x * centered.z
            covariance[1][0] += centered.y * centered.x
            covariance[1][1] += centered.y * centered.y
            covariance[1][2] += centered.y * centered.z
            covariance[2][0] += centered.z * centered.x
            covariance[2][1] += centered.z * centered.y
            covariance[2][2] += centered.z * centered.z
        }
        let scale = 1.0 / Double(vectors.count)
        for row in 0..<3 {
            for col in 0..<3 {
                covariance[row][col] *= scale
            }
        }

        let decomposition = jacobiEigenDecomposition(covariance)
        guard let minIndex = decomposition.values.enumerated().min(by: { $0.element < $1.element })?.offset else {
            return nil
        }
        let normalVector = SIMD3<Double>(
            decomposition.vectors[0][minIndex],
            decomposition.vectors[1][minIndex],
            decomposition.vectors[2][minIndex]
        )
        let normalLength = simd_length(normalVector)
        guard normalLength > 0 else { return nil }
        let unitNormal = normalVector / normalLength
        let perpendicularAcceleration = vectors.map { simd_dot($0, unitNormal) }
        return RecordingAnalysis(planeNormal: unitNormal, perpendicularAcceleration: perpendicularAcceleration)
    }

    private static func jacobiEigenDecomposition(_ matrix: [[Double]]) -> (values: [Double], vectors: [[Double]]) {
        var a = matrix
        var v = [
            [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0],
            [0.0, 0.0, 1.0]
        ]

        for _ in 0..<20 {
            var p = 0
            var q = 1
            var maxValue = abs(a[p][q])
            for i in 0..<3 {
                for j in (i + 1)..<3 {
                    let value = abs(a[i][j])
                    if value > maxValue {
                        maxValue = value
                        p = i
                        q = j
                    }
                }
            }
            if maxValue < 1e-10 {
                break
            }

            let app = a[p][p]
            let aqq = a[q][q]
            let apq = a[p][q]
            let phi = 0.5 * atan2(2.0 * apq, aqq - app)
            let c = cos(phi)
            let s = sin(phi)

            for i in 0..<3 {
                let aip = a[i][p]
                let aiq = a[i][q]
                a[i][p] = c * aip - s * aiq
                a[i][q] = s * aip + c * aiq
            }
            for i in 0..<3 {
                let api = a[p][i]
                let aqi = a[q][i]
                a[p][i] = c * api - s * aqi
                a[q][i] = s * api + c * aqi
            }
            a[p][p] = c * c * app - 2.0 * s * c * apq + s * s * aqq
            a[q][q] = s * s * app + 2.0 * s * c * apq + c * c * aqq
            a[p][q] = 0
            a[q][p] = 0

            for i in 0..<3 {
                let vip = v[i][p]
                let viq = v[i][q]
                v[i][p] = c * vip - s * viq
                v[i][q] = s * vip + c * viq
            }
        }

        let values = [a[0][0], a[1][1], a[2][2]]
        return (values, v)
    }
}
