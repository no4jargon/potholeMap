# accelsensordatarecording

A SwiftUI iPhone app that records synced 3D motion data (via `CMDeviceMotion`) and GPS coordinates with a single record/stop button. The UI is intentionally modeled after the iPhone Voice Memos app for a simple, familiar workflow.

## Features
- One-tap start/stop recording like Voice Memos.
- Writes a CSV file with motion + GPS samples while recording.
- Uses `CMDeviceMotion` (user acceleration + rotation + gravity) for pothole detection research.
- Location updates tuned for automotive navigation.

## Project setup (Xcode on macOS)
1. Clone this repository.
2. Open `accelsensordatarecording.xcodeproj` in Xcode.
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
- Motion permission: **Required** for `CMDeviceMotion` (prompted on first recording).
- The Xcode project is included, so the repo opens directly in Xcode on macOS.

## Troubleshooting
If you see a warning like `Error reading file ... com.apple.CoreMotion.plist` when running on a device, it typically means iOS is blocking access to the managed Core Motion preferences file. This is an OS-level permissions check and is commonly logged when Motion & Fitness access is denied or restricted. To resolve:

1. Confirm the app has **Motion & Fitness** access in **Settings → Privacy & Security → Motion & Fitness**.
2. If the device is managed (MDM), check whether motion access is restricted by a configuration profile.
3. Rebuild and reinstall the app after updating permissions.
