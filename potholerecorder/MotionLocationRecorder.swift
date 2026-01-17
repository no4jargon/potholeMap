import CoreLocation
import CoreMotion
import Foundation

final class MotionLocationRecorder: NSObject, CLLocationManagerDelegate {
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private let queue = OperationQueue()

    private var currentLocation: CLLocation?
    private var fileHandle: FileHandle?
    private var recordingURL: URL?

    private(set) var title = "Pothole Recording"

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .automotiveNavigation
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1
        queue.name = "pothole.motion.queue"
    }

    func start() {
        title = "Pothole Recording"
        setupFile()
        requestPermissions()
        startLocationUpdates()
        startMotionUpdates()
    }

    func stop() -> URL? {
        motionManager.stopDeviceMotionUpdates()
        locationManager.stopUpdatingLocation()
        fileHandle?.closeFile()
        fileHandle = nil
        return recordingURL
    }

    private func requestPermissions() {
        locationManager.requestWhenInUseAuthorization()
    }

    private func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0

        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, error in
            guard let self, let motion, error == nil else { return }
            self.writeSample(from: motion)
        }
    }

    private func setupFile() {
        let url = RecordingFileStore.makeRecordingURL()
        recordingURL = url
        FileManager.default.createFile(atPath: url.path, contents: nil)
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        fileHandle = handle
        let header = "timestamp,latitude,longitude,altitude,speed,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,gravity_x,gravity_y,gravity_z\n"
        if let data = header.data(using: .utf8) {
            handle.write(data)
        }
    }

    private func writeSample(from motion: CMDeviceMotion) {
        guard let handle = fileHandle else { return }
        let timestamp = Date().timeIntervalSince1970
        let location = currentLocation
        let latitude = location?.coordinate.latitude ?? 0
        let longitude = location?.coordinate.longitude ?? 0
        let altitude = location?.altitude ?? 0
        let speed = location?.speed ?? 0
        let acceleration = motion.userAcceleration
        let rotation = motion.rotationRate
        let gravity = motion.gravity
        let line = String(format: "%.3f,%.6f,%.6f,%.2f,%.2f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n",
                          timestamp,
                          latitude,
                          longitude,
                          altitude,
                          speed,
                          acceleration.x,
                          acceleration.y,
                          acceleration.z,
                          rotation.x,
                          rotation.y,
                          rotation.z,
                          gravity.x,
                          gravity.y,
                          gravity.z)
        if let data = line.data(using: .utf8) {
            handle.write(data)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
}
