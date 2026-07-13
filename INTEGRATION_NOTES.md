# 🔗 Integration Notes - Multi-Window App

## How This Project Relates to cv-wep-frontend

### Shared Components

Both projects use the same gRPC communication layer:

1. **gRPC Client**: `CVMainClientService`
   - Located in cv-wep-frontend: `lib/core/api/cvmain_client.dart`
   - Reused in multi-window-app: `lib/core/api/cvmain_client.dart`
   - Same backend connection logic

2. **Configuration Service**: `ConfigService`
   - Manages locker IP address and preferences
   - Uses SharedPreferences for persistence
   - Works on both mobile and desktop

3. **Protocol Buffers**: Service definitions
   - Auto-generated from .proto files
   - Located in `lib/core/generated/`
   - Required for gRPC communication

### What's Different

| Aspect | cv-wep-frontend | multi-window-app |
|--------|-----------------|------------------|
| **Platform** | Mobile (iOS/Android) | Desktop (Linux/macOS) |
| **UI Framework** | Material 3 Mobile | Material 3 Desktop |
| **Use Case** | Customer app | Operator/Admin panel |
| **Screen Size** | Small (mobile) | Large (desktop) |
| **Input** | Touch | Mouse/Keyboard |
| **Deployment** | App Store/Play Store | Docker/RPi direct |

### What's the Same

- ✅ gRPC backend communication
- ✅ Protocol buffer messages
- ✅ Locker hardware control logic
- ✅ Configuration system
- ✅ Error handling patterns
- ✅ Logging framework

## Copying Protocol Buffer Files

**CRITICAL STEP**: This project needs the generated protocol buffer files from cv-wep-frontend.

### How to Copy

```bash
# From cv-wep-frontend project root:
cd /Users/vishnusharma/project/Vault/cv-wep-frontend

# Copy generated protocol buffer files
cp lib/core/generated/service.pb.dart \
   /Users/vishnusharma/project/Vault/multi-window-app/lib/core/generated/

cp lib/core/generated/service.pbgrpc.dart \
   /Users/vishnusharma/project/Vault/multi-window-app/lib/core/generated/

cp lib/core/generated/service.pbjson.dart \
   /Users/vishnusharma/project/Vault/multi-window-app/lib/core/generated/
```

### What These Files Contain

1. **service.pb.dart**
   - Message class definitions (LockRequest, GeneralResponse, etc.)
   - Protocol buffer message builders
   - JSON serialization

2. **service.pbgrpc.dart**
   - gRPC service client (`CommsServiceClient`)
   - gRPC method stubs
   - Channel configuration

3. **service.pbjson.dart**
   - JSON descriptor information
   - Used internally by protobuf library

### Verifying the Copy

```bash
cd /Users/vishnusharma/project/Vault/multi-window-app

# Check files exist
ls -la lib/core/generated/

# Should output:
# service.pb.dart
# service.pbgrpc.dart
# service.pbjson.dart
```

## Importing gRPC Components

Once protocol buffers are in place, the imports work like this:

```dart
// In cvmain_client.dart
import 'package:grpc/grpc.dart';
import '../config/config_service.dart';
import '../utilities/logging.dart';

// These are auto-generated from protocol buffers:
// - CommsServiceClient
// - LockRequest
// - GeneralResponse
// - BasicResponse
// - Empty
// - VersionResponse
```

## Testing the Integration

### 1. Verify gRPC Connection

```bash
# Start the app
cd /Users/vishnusharma/project/Vault/multi-window-app
flutter run

# Check console output:
# 🚀 Initializing Multi-Window App...
# 🔌 Initializing gRPC client at 192.168.1.100:50051...
# ✅ gRPC channel established to 192.168.1.100:50051
```

### 2. Test Backend Connectivity

```dart
// In the app UI:
1. Click "Refresh Status" button
2. If green: Backend is reachable ✅
3. If red: Backend is offline ❌
```

### 3. Test Locker Operations

```dart
// With backend online:
1. Enter compartment ID: 5
2. Click "Open"
3. Should see: "Compartment opened"
4. Physical door should open
5. Click "Close"
6. Should see: "Compartment closed"
7. Physical door should close
```

## Updating Both Projects

If you make changes to protocol buffers (.proto files):

```bash
# 1. Edit the .proto file
nano lib/core/generated/service.proto

# 2. Regenerate protocol buffer code
# (Run from project root with protoc compiler)
protoc --dart_out=grpc:lib/core/generated lib/core/generated/service.proto

# 3. Copy to multi-window-app
cp lib/core/generated/service.pb*.dart \
   /Users/vishnusharma/project/Vault/multi-window-app/lib/core/generated/

# 4. Run pub get in both projects
flutter pub get
```

## Architecture Comparison

### cv-wep-frontend (Mobile)
```
Customer App (Flutter Mobile)
        ↓
  Material UI (Mobile)
        ↓
    BLoC Layer
        ↓
  CVMainClientService (gRPC)
        ↓
  CVMain Backend
        ↓
  Physical Locker
```

### multi-window-app (Desktop)
```
Operator App (Flutter Desktop)
        ↓
  Material UI (Desktop)
        ↓
    BLoC Layer
        ↓
  CVMainClientService (gRPC)
        ↓
  CVMain Backend
        ↓
  Physical Locker
```

**Same backend, different client!**

## Code Reusability

### Reused as-is (80%+)
- ✅ CVMainClientService
- ✅ ConfigService
- ✅ Protocol buffer types
- ✅ LockerService wrapper
- ✅ gRPC channel setup

### Adapted for Desktop (20%)
- 📱 UI/UX (mobile screens → desktop windows)
- 🎨 Layout (Material Mobile → Material Desktop)
- ⌨️ Input handling (touch → mouse/keyboard)
- 🎯 Navigation patterns (drawer → sidebar)

## Maintenance Notes

### When Updating Backend

1. Backend changes .proto file
2. Regenerate code in cv-wep-frontend
3. Copy to multi-window-app
4. Both apps automatically use new protocol

### When Adding Features

1. Add to BLoC events/states
2. Implement in LockerService
3. Update UI in screens
4. Both mobile and desktop benefit

### When Fixing Bugs

1. Fix in CVMainClientService (impacts both)
2. Fix UI in respective apps (mobile or desktop)
3. Test across both platforms if shared code

## Deployment Considerations

### Mobile Deployment (cv-wep-frontend)
- App Store / Google Play
- Automatic updates
- Push notifications
- Mobile-specific features

### Desktop Deployment (multi-window-app)
- Docker container
- Direct Linux installation
- Raspberry Pi distribution
- Headless mode support

## Performance Notes

### Network Bandwidth
Both apps use the same gRPC channel:
- Binary protocol (smaller than JSON)
- gzip compression enabled
- Typical message: ~200 bytes
- Suitable for WiFi/LAN

### Hardware Requirements

**Mobile (cv-wep-frontend)**
- RAM: 512MB - 2GB
- CPU: Modern mobile processor
- Network: WiFi or cellular

**Desktop (multi-window-app)**
- RAM: 1GB - 4GB
- CPU: Modern desktop/embedded CPU
- Network: Ethernet or WiFi
- Storage: 300MB+ (Flutter runtime)

## Troubleshooting Cross-Project Issues

### "Cannot import 'service.pb.dart'"

```
Solution: Copy protocol buffer files from cv-wep-frontend
```

### "CommsServiceClient not found"

```
Solution: Verify service.pbgrpc.dart is present
         Check import path is correct
         Run: flutter pub get
```

### "Different versions of protocol buffers"

```
Solution: Update pubspec.yaml version to match cv-wep-frontend
         Run: flutter pub get
         Delete pubspec.lock and regenerate
```

## Future Enhancements

Possible improvements that benefit both projects:

1. **Offline Mode**
   - Cache recent commands
   - Sync when online

2. **Multi-locker Support**
   - Control multiple locker systems
   - Load balancing

3. **Advanced Logging**
   - Audit trail
   - Event history

4. **Mobile Desktop Bridge**
   - One app, multiple platforms
   - Shared code base (90%+)

5. **Web Version**
   - Browser-based UI
   - Cloud deployment

---

**Key Takeaway**: This is NOT a separate project. It's the **same gRPC backend with different UIs**. The backend stays the same; we just added a desktop control panel!
