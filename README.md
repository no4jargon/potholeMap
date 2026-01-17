# PotholeRecorder

A SwiftUI iPhone app that records synced 3D motion data (via `CMDeviceMotion`) and GPS coordinates with a single record/stop button. The UI is intentionally modeled after the iPhone Voice Memos app for a simple, familiar workflow.

## Features
- One-tap start/stop recording like Voice Memos.
- Writes a CSV file with motion + GPS samples while recording.
- Uses `CMDeviceMotion` (user acceleration + rotation + gravity) for pothole detection research.
- Location updates tuned for automotive navigation.

## Project setup (Xcode on macOS)
1. Clone this repository.
2. Open `PotholeRecorder.xcodeproj` in Xcode.
3. Select a simulator or a connected iPhone.
4. Build and run.

## Data format
Each recording is saved as a CSV file in the app’s Documents directory with the following columns:

```
timestamp,latitude,longitude,altitude,speed,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,gravity_x,gravity_y,gravity_z
```

`timestamp` is a Unix epoch in seconds. The motion values come from `CMDeviceMotion` using the `.xArbitraryZVertical` reference frame to make pothole impacts easier to analyze.

## Notes
- Location permission: **When In Use**.
- Motion permission: **Required** for `CMDeviceMotion`.
- The Xcode project is included, so the repo opens directly in Xcode on macOS.
