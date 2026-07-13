# ⚡ Quick Start - Multi-Window App

## 5-Minute Setup

### Prerequisites
- [ ] Flutter 3.0+ installed
- [ ] Git or file access to cv-wep-frontend project
- [ ] Linux desktop or Raspberry Pi 5
- [ ] Locker backend IP address known

### Step 1: Copy Protocol Buffer Files (2 min)

```bash
# Copy these 3 files from cv-wep-frontend:
cp /Users/vishnusharma/project/Vault/cv-wep-frontend/lib/core/generated/service.pb.dart \
   lib/core/generated/

cp /Users/vishnusharma/project/Vault/cv-wep-frontend/lib/core/generated/service.pbgrpc.dart \
   lib/core/generated/

cp /Users/vishnusharma/project/Vault/cv-wep-frontend/lib/core/generated/service.pbjson.dart \
   lib/core/generated/
```

### Step 2: Get Dependencies (1 min)

```bash
cd /Users/vishnusharma/project/Vault/multi-window-app
flutter pub get
```

### Step 3: Run the App (2 min)

```bash
# On current machine
flutter run

# Or on specific Linux device
flutter run -d linux
```

### Step 4: Configure Backend (optional)

Default is `192.168.1.100:50051`

In app:
1. Go to "⚙️ Configuration" section
2. Update IP address if needed
3. Click "Update Address"

---

## First Test

### Check Backend Status
1. Click "Refresh Status"
2. Should show: **Online** (green dot)
3. If red: Backend is offline or unreachable

### Test Locker Open/Close
1. Enter compartment ID: `5`
2. Click "Open"
3. Should see success message
4. Physical door opens (5-10 sec)
5. Click "Close"
6. Door closes

---

## File Structure (What Goes Where)

```
✅ Already Created:
├── lib/main.dart                         # App entry point
├── lib/bloc/locker/                      # State management
├── lib/core/api/cvmain_client.dart       # gRPC wrapper
├── lib/core/config/config_service.dart   # Configuration
├── lib/core/services/locker_service.dart # Business logic
├── lib/core/utilities/logging.dart       # Logging
├── lib/screens/locker_control_screen.dart # Main UI
├── pubspec.yaml                          # Dependencies
└── SETUP_GUIDE.md                        # Full setup guide

⏳ You Need to Add:
└── lib/core/generated/
    ├── service.pb.dart          # FROM cv-wep-frontend
    ├── service.pbgrpc.dart      # FROM cv-wep-frontend
    └── service.pbjson.dart      # FROM cv-wep-frontend
```

---

## Common Commands

```bash
# Build for Linux
flutter build linux --release

# Build for Raspberry Pi (from RPi)
flutter build linux --release

# Run tests
flutter test

# Clean build
flutter clean
flutter pub get

# Check for issues
flutter analyze
```

---

## What Each File Does

| File | Purpose |
|------|---------|
| `main.dart` | App startup, dependency injection |
| `locker_control_screen.dart` | Main UI with buttons and inputs |
| `locker_bloc.dart` | Handles user actions, manages state |
| `cvmain_client.dart` | Sends gRPC requests to backend |
| `locker_service.dart` | High-level locker operations |
| `config_service.dart` | Stores user preferences |
| `logging.dart` | Logging configuration |

---

## Verify Installation

```bash
# 1. Check Flutter
flutter --version
# Should show: Flutter 3.0.0 or higher

# 2. Check dependencies
flutter pub get
# Should complete without errors

# 3. Check imports
grep -r "import 'package:grpc" lib/
# Should find: lib/core/api/cvmain_client.dart

# 4. Check generated files
ls -la lib/core/generated/
# Should show: service.pb*.dart files
```

---

## Troubleshooting Quick Fixes

### Error: "Cannot import 'service.pb.dart'"
→ Copy protocol buffer files from cv-wep-frontend (Step 1)

### Error: "Flutter not found"
→ Add Flutter to PATH or reinstall

### App won't start
→ Run `flutter clean` then `flutter pub get`

### Cannot reach backend
→ Check locker IP in Configuration section
→ Verify network connectivity
→ Check backend is powered on

---

## Next Steps

1. ✅ Complete 5-minute setup above
2. ✅ Test backend connectivity (check status)
3. ✅ Test locker operations (open/close)
4. ✅ Read SETUP_GUIDE.md for deployment
5. ✅ Read INTEGRATION_NOTES.md for details

---

## Getting Help

**In the app:**
- Check console output (shows all operations)
- Status card shows backend connectivity
- Error messages explain what went wrong

**In terminal:**
- Check logs: `flutter run` shows debug output
- Run with verbose: `flutter run -v`

**In code:**
- All operations logged with emojis: 📭 🔒 ✅ ❌ 📡

---

**Status**: Ready to use!  
**Time to setup**: ~5 minutes  
**Time to first test**: ~10 minutes  
**Time to deployment**: 1-2 hours
