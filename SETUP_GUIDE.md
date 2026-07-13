# 🚀 Multi-Window App - Setup & Integration Guide

## Overview

This is a Flutter Desktop application for controlling physical lockers via gRPC. It's designed to run on Raspberry Pi 5 (or any Linux desktop) and communicate with the CVMain backend service.

## Project Structure

```
multi-window-app/
├── lib/
│   ├── bloc/
│   │   └── locker/
│   │       ├── locker_bloc.dart       # State management
│   │       ├── locker_event.dart      # Events
│   │       └── locker_state.dart      # States
│   ├── core/
│   │   ├── api/
│   │   │   └── cvmain_client.dart     # gRPC client wrapper
│   │   ├── config/
│   │   │   └── config_service.dart    # Configuration & preferences
│   │   ├── generated/
│   │   │   └── [protocol buffer files]
│   │   ├── services/
│   │   │   └── locker_service.dart    # High-level locker operations
│   │   └── utilities/
│   │       └── logging.dart           # Logger setup
│   ├── screens/
│   │   └── locker_control_screen.dart # Main UI screen
│   └── main.dart                      # App entry point
├── pubspec.yaml                       # Dependencies
├── SETUP_GUIDE.md                     # This file
└── INTEGRATION_NOTES.md               # Integration details
```

## Prerequisites

### System Requirements
- **Flutter**: 3.0.0 or higher
- **Dart**: 3.0.0 or higher
- **Platform**: Linux (desktop) or Raspberry Pi 5
- **RAM**: 2+ GB recommended
- **Network**: Access to locker backend on same network

### Backend Requirements
- **CVMain Service** running on locker hardware
- **gRPC Port**: 50051 (default, configurable)
- **Protocol**: HTTP/2 (unsecured, local network only)
- **Network**: Same network as app

## Installation Steps

### 1. Clone or Copy the Project

```bash
# If using from the provided location
cd /Users/vishnusharma/project/Vault/multi-window-app

# Or copy to your desired location
cp -r multi-window-app ~/projects/
cd ~/projects/multi-window-app
```

### 2. Install Flutter (if not already installed)

```bash
# On macOS
brew install flutter

# On Linux (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install flutter

# Or download from https://flutter.dev/docs/get-started/install
```

### 3. Enable Desktop Support

```bash
# Enable Linux desktop
flutter config --enable-linux-desktop

# Enable macOS desktop (if needed)
flutter config --enable-macos-desktop
```

### 4. Get Dependencies

```bash
flutter pub get
```

### 5. Add Protocol Buffer Support (IMPORTANT)

This project uses gRPC, which requires protocol buffer files. You need to:

1. Copy the generated protocol buffer files from the cv-wep-frontend project:
   ```bash
   # From cv-wep-frontend project:
   cp lib/core/generated/service.pb.dart lib/core/generated/
   cp lib/core/generated/service.pbgrpc.dart lib/core/generated/
   cp lib/core/generated/service.pbjson.dart lib/core/generated/
   ```

2. Or generate them from .proto files:
   ```bash
   # Install protoc compiler
   # Then run protocol buffer code generation
   # (Instructions depend on your .proto file location)
   ```

### 6. Run the Application

```bash
# Run on current machine
flutter run

# Run on specific device
flutter run -d linux

# Run in release mode for RPi
flutter run --release
```

## Configuration

### Locker Backend Address

The app stores the locker backend address in SharedPreferences.

**Default:** `192.168.1.100:50051`

### Changing at Runtime

1. Open the app
2. Go to "⚙️ Configuration" section
3. Enter your locker's IP and port (format: `IP:PORT`)
4. Click "Update Address"

### Changing Programmatically

```dart
final config = ConfigService();
await config.setLockerAddress('10.0.0.5:50051');
```

## Usage

### Opening a Compartment

1. Enter compartment ID (1-12) in the input field
2. Click "Open" button
3. Door will open (5-10 seconds)
4. Check status card for result

### Closing a Compartment

1. Enter compartment ID (1-12)
2. Click "Close" button
3. Door will close
4. Check status for confirmation

### Checking Backend Status

1. Click "Refresh Status" to check if backend is online
2. Green indicator = Online and responsive
3. Red indicator = Offline or unreachable

## Raspberry Pi 5 Deployment

### Setup on RPi 5

```bash
# 1. Install Flutter on RPi
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_arm64.tar.xz
tar xf flutter_linux_arm64.tar.xz
export PATH="$PATH:$HOME/flutter/bin"

# 2. Verify installation
flutter --version

# 3. Clone/copy the app
cd ~/projects
git clone <your-repo> multi-window-app
cd multi-window-app

# 4. Get dependencies
flutter pub get

# 5. Run the app
flutter run --release
```

### Creating a Desktop Entry (for Linux)

To run the app from the applications menu:

```bash
# Create a .desktop file
cat > ~/.local/share/applications/locker-control.desktop << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Locker Control
Comment=Physical Locker Control System
Exec=/home/pi/projects/multi-window-app/build/linux/x64/release/bundle/multi_window_app
Icon=folder-lock
Categories=Utility;
DESKTOP
```

## Troubleshooting

### "Cannot reach backend" Error

1. Check if locker hardware is powered on
2. Verify network connectivity between app and locker
3. Check the IP address configuration
4. Ping the locker's IP: `ping 192.168.1.100`

### gRPC Connection Timeout

1. Increase network timeout in `cvmain_client.dart`
2. Check firewall rules on both sides
3. Verify gRPC port (usually 50051) is open

### Protocol Buffer Import Errors

1. Ensure generated .pb.dart files are in `lib/core/generated/`
2. Run `flutter pub get` again
3. If needed, regenerate from .proto files

### UI Not Updating

1. Ensure BLoC is properly registered in `main.dart`
2. Check that LockerBloc dependencies are correct
3. Look at console output for error messages

## Architecture Overview

### Data Flow

```
User Action (Button Click)
        ↓
    BLoC Event (e.g., OpenCompartmentEvent)
        ↓
    LockerService (High-level operations)
        ↓
    CVMainClientService (gRPC wrapper)
        ↓
    gRPC Client Channel
        ↓
    Backend (CVMain service)
        ↓
    Physical Hardware (Solenoid/Motor)
        ↓
    Response back through same chain
        ↓
    BLoC State Update
        ↓
    UI Rebuild
```

### Key Components

**LockerBloc**: State management using Flutter BLoC pattern
- Handles user actions
- Manages loading/success/error states
- Emits state changes to UI

**LockerService**: High-level business logic
- Wraps gRPC client
- Provides user-friendly result objects
- Handles error scenarios

**CVMainClientService**: gRPC communication
- Manages gRPC channel
- Sends/receives protocol buffer messages
- Handles network errors

**ConfigService**: Configuration management
- Stores locker address
- Persists user preferences
- Provides singleton access

## Development Notes

### Adding New Features

1. Add new events to `locker_event.dart`
2. Add new states to `locker_state.dart`
3. Handle events in `locker_bloc.dart`
4. Update UI in `locker_control_screen.dart`

### Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Build for production
flutter build linux --release
```

### Logging

All operations are logged using the `logger` utility. Check console output:

```
🚀 [INFO] Initializing Multi-Window App...
📭 [INFO] Opening compartment 5...
✅ [INFO] Compartment 5 opened successfully
```

## Support & Resources

- **Flutter Docs**: https://flutter.dev/docs
- **gRPC Dart Guide**: https://grpc.io/docs/languages/dart/
- **Protocol Buffers**: https://developers.google.com/protocol-buffers
- **Flutter BLoC**: https://bloclibrary.dev/

## Next Steps

1. ✅ Copy protocol buffer generated files
2. ✅ Configure locker backend address
3. ✅ Test gRPC connectivity
4. ✅ Verify physical locker operations
5. ✅ Deploy to Raspberry Pi
6. ✅ Set up automatic launch

---

**Version:** 1.0.0  
**Last Updated:** July 10, 2026  
**Status:** Ready for Integration
