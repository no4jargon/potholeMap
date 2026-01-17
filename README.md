# PotholeRecorder

A SwiftUI iPhone app that records synced 3D motion data (via `CMDeviceMotion`) and GPS coordinates with a single record/stop button. The UI is intentionally modeled after the iPhone Voice Memos app for a simple, familiar workflow.

## Features
- One-tap start/stop recording like Voice Memos.
- Writes a CSV file with motion + GPS samples while recording.
- Uses `CMDeviceMotion` (user acceleration + rotation + gravity) for pothole detection research.
- Location updates tuned for automotive navigation.

## Project setup
1. Open Xcode.
2. Create a new **iOS App** project named **PotholeRecorder** using SwiftUI.
3. Replace the generated files with the contents in the `PotholeRecorder/` folder in this repository.
4. Ensure your target uses `Info.plist` from `PotholeRecorder/Info.plist` (or merge the permissions into your app Info.plist).

## Data format
Each recording is saved as a CSV file in the app’s Documents directory with the following columns:

```
timestamp,latitude,longitude,altitude,speed,accel_x,accel_y,accel_z,gyro_x,gyro_y,gyro_z,gravity_x,gravity_y,gravity_z
```

`timestamp` is a Unix epoch in seconds. The motion values come from `CMDeviceMotion` using the `.xArbitraryZVertical` reference frame to make pothole impacts easier to analyze.

## Notes
- Location permission: **When In Use**.
- Motion permission: **Required** for `CMDeviceMotion`.
- This repository provides the SwiftUI source structure; you’ll still need to create the Xcode project container.
