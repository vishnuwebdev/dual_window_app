# multi_window_app — Admin / Customer dual-window POC

A Flutter **desktop** POC with two independent native windows (Admin +
Customer), built to run on macOS today and on Linux / Raspberry Pi 5 with
two HDMI monitors later, without restructuring the app.

## Project structure

```
lib/
  main.dart                        # single entrypoint for every window
  models/
    window_type.dart               # AppWindowRole + WindowArgs (window identity)
    customer_message.dart          # the message payload sent Admin -> Customer
  services/
    window_service.dart            # creates + positions native windows
    messaging_service.dart         # WindowMethodChannel IPC, isolated from UI
  windows/
    admin_window.dart              # Admin window's MaterialApp/Navigator root
    customer_window.dart           # Customer window's MaterialApp/Navigator root
  pages/
    admin/
      admin_home_page.dart
      admin_settings_page.dart
    customer/
      customer_welcome_page.dart
      customer_details_page.dart
```

Every file has a doc comment at the top explaining *why* it exists and any
desktop-specific concept it demonstrates — read those first; this README
covers the parts that can't live as code comments: one-time project setup
and the path to Raspberry Pi deployment.

## Why these packages

Flutter does not yet have official, stable, native multi-window support —
it's under active development (Canonical is leading the Linux/desktop
side), but still experimental. The community-standard, actively maintained
solution is:

- **`desktop_multi_window`** — creates additional native windows, each
  backed by its own Flutter *engine* (own isolate, own memory), and
  provides `WindowMethodChannel` for message-passing between them.
- **`window_manager`** — lets a window control its own size, position,
  decorations, and fullscreen state.
- **`screen_retriever`** — reports the physical displays attached to the
  machine (position, size), which is how we decide where each window goes.

All three support macOS, Linux, and Windows with the same Dart API, which
is exactly why this architecture carries over to the Raspberry Pi with no
redesign — only the *numbers* (which display, fullscreen or not) change.

## One-time setup (do this before `lib/` will compile and run)

The `lib/` folder in this project is complete, but a Flutter *desktop* app
also needs native runner projects (`macos/`, `linux/`, `windows/`) that
`flutter create` generates for you, plus two small edits those templates
don't know to make on their own.

1. **Scaffold the native runners** (run once, from this project's root):

   ```bash
   flutter create --platforms=macos,linux,windows .
   ```

   This adds `macos/`, `linux/`, and `windows/` folders alongside `lib/`
   without touching anything you already have. If it prompts to overwrite
   `pubspec.yaml`, say no (keep the one in this project) — everything
   else it generates is native scaffolding you need.

2. **Fetch packages:**

   ```bash
   flutter pub get
   ```

3. **Register plugins in every new window (required, one-time, per
   platform).** This is the one genuinely non-obvious desktop-specific
   step: each window `desktop_multi_window` creates is a *separate Flutter
   engine*, and plugin method channels do not automatically attach to
   engines that didn't exist when the app started. Without this step,
   `window_manager` calls inside the Customer window will silently fail
   with a `MissingPluginException`.

   **macOS** — edit `macos/Runner/MainFlutterWindow.swift`:

   ```diff
    import Cocoa
    import FlutterMacOS
   +import desktop_multi_window

    class MainFlutterWindow: NSWindow {
      override func awakeFromNib() {
        ...
        RegisterGeneratedPlugins(registry: flutterViewController)
   +
   +    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
   +      RegisterGeneratedPlugins(registry: controller)
   +    }
   +
        super.awakeFromNib()
      }
    }
   ```

   **Linux** — edit `linux/my_application.cc`:

   ```diff
    #include "my_application.h"
    #include <flutter_linux/flutter_linux.h>
    #include "flutter/generated_plugin_registrant.h"
   +#include "desktop_multi_window/desktop_multi_window_plugin.h"

    // inside my_application_activate():
      fl_register_plugins(FL_PLUGIN_REGISTRY(view));
   +
   +  desktop_multi_window_plugin_set_window_created_callback(
   +      [](FlPluginRegistry* registry) { fl_register_plugins(registry); });
   +
      gtk_widget_grab_focus(GTK_WIDGET(view));
   ```

   **Windows** — edit `windows/runner/flutter_window.cpp` (only needed if
   you plan to also ship on Windows):

   ```diff
    #include "flutter/generated_plugin_registrant.h"
   +#include "desktop_multi_window/desktop_multi_window_plugin.h"

      RegisterPlugins(flutter_controller_->engine());
   +  DesktopMultiWindowSetWindowCreatedCallback([](void *controller) {
   +    auto *flutter_view_controller =
   +        reinterpret_cast<flutter::FlutterViewController *>(controller);
   +    RegisterPlugins(flutter_view_controller->engine());
   +  });
      SetChildContent(flutter_controller_->view()->GetNativeWindow());
   ```

4. **Run it:**

   ```bash
   flutter run -d macos
   ```

   You should see the Admin window appear on the left half of your screen
   and the Customer window automatically appear on the right half, both
   showing "Waiting for message..." until you type something into Admin
   and press "Send to Customer".

## Concept recap: what makes the two windows independent

- **Separate engines, not separate widgets.** Each window is its own OS
  process-level Flutter engine with its own isolate. This is *stronger*
  isolation than e.g. two `Navigator`s in one engine — there is no shared
  Dart memory at all between Admin and Customer. A `ChangeNotifier`
  singleton like `MessagingService.instance` exists independently in each
  engine; it is not automatically kept in sync. The *only* thing that
  crosses the boundary is what you explicitly send over
  `WindowMethodChannel`.
- **Independent `Navigator`s "for free."** Because each window runs its
  own `MaterialApp`, each gets its own `Navigator` automatically — no extra
  setup needed to keep Home→Settings navigation in Admin from affecting
  Welcome→Details navigation in Customer.
- **One `main()`, branching on arguments.** There's only one compiled app.
  Every window (the first, and every one created afterwards) runs the same
  `main()`; `WindowController.fromCurrentEngine().arguments` is how each
  one learns which role (`admin`/`customer`) it should render.

---

## 1. Building this for Linux

Desktop support is a normal Flutter build target, not a separate codebase:

```bash
flutter config --enable-linux-desktop   # one-time, if not already on
flutter create --platforms=linux .      # if you skipped this above
flutter pub get
flutter build linux --release
```

The output binary and bundled assets land in
`build/linux/<arch>/release/bundle/`. You need the standard Linux desktop
build toolchain installed first: `clang`, `cmake`, `ninja-build`,
`pkg-config`, and `libgtk-3-dev` (Flutter's Linux embedder is GTK3-based).
On Debian/Ubuntu/Raspberry Pi OS:

```bash
sudo apt update
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev
```

Nothing in `lib/` changes for Linux — `desktop_multi_window`,
`window_manager`, and `screen_retriever` all ship Linux implementations of
the same Dart API you already used on macOS.

## 2. Deploying to a Raspberry Pi 5

The Pi 5's CPU is `arm64`. Flutter's Linux desktop target supports
`arm64` natively, but Flutter's own precompiled `linux-arm64` engine
artifacts are newer/less battle-tested than `x64` — recommended path:

**Build directly on the Pi (simplest, most reliable):**

1. Flash **Raspberry Pi OS (64-bit)** to the Pi 5.
2. Install the Flutter SDK on the Pi itself (same `flutter` CLI, arm64
   build), then run through the same steps as the Linux section above,
   on-device:
   ```bash
   sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev git curl
   flutter build linux --release
   ```
3. Copy (or `flutter build` directly produces) the bundle at
   `build/linux/arm64/release/bundle/`. Run it with
   `./bundle/multi_window_app`.

**Cross-compiling from an x64 machine onto the Pi** is possible (Docker +
an arm64 sysroot) but adds real complexity — for a POC, building natively
on the Pi 5 (it's plenty fast for this) is the path of least resistance.
Once you're production-hardening this, a cross-compile CI pipeline is the
next step.

**Autostart on boot:** package the bundle as a systemd service or a
`.desktop` autostart entry in `~/.config/autostart/`, so the kiosk comes up
without a human logging in and double-clicking anything.

## 3. Showing the two windows on two HDMI monitors

This is the part our architecture already handles — **no code changes,
only OS-level display configuration:**

- Raspberry Pi OS treats both HDMI outputs as one combined virtual desktop
  by default (exactly like plugging a second monitor into a Mac). You
  arrange *where* each HDMI output sits in that virtual desktop using the
  desktop environment's display settings, or from the command line, e.g.:
  ```bash
  xrandr --output HDMI-1 --pos 0x0 --output HDMI-2 --pos 1920x0
  ```
  (exact output names come from `xrandr` with no arguments; under Wayland/
  Wayfire — the default compositor on recent Raspberry Pi OS — the
  equivalent lives in `~/.config/wayfire.ini`'s `[output:HDMI-A-1]` /
  `[output:HDMI-A-2]` sections.)
- **This is the "where are the monitor coordinates configured" answer:**
  the OS's display arrangement is the source of truth. Our Dart code in
  `WindowService._resolvePlacement()` (in `lib/services/window_service.dart`)
  just *reads* that arrangement back via
  `screenRetriever.getAllDisplays()` and places Admin on `displays[0]` and
  Customer on `displays[1]`. If the two windows land on the wrong monitor
  or overlap on the Pi, fix the OS-level arrangement above — don't hard-code
  pixel offsets in Dart.
- If your two HDMI ports are physically wired in the opposite order from
  what you want (e.g. HDMI0 should be Customer, not Admin), swap the
  `displays[0]` / `displays[1]` assignment in `_resolvePlacement()` — that
  one line is the only thing tying a *role* to a *physical port*.

## 4. Changes needed before shipping to the Pi

None of these are structural — they're kiosk-mode polish, already flagged
as commented-out code in `lib/services/window_service.dart`:

- **Fullscreen, no window chrome:** uncomment
  `windowManager.setAsFrameless()` and `windowManager.setFullScreen(true)`
  so each window fills its entire HDMI output edge-to-edge instead of
  showing a title bar sized to a fraction of the screen.
- **Disable screen blanking / DPMS sleep**, so an idle kiosk display
  doesn't go black: `xset s off -dpms` (X11) or the equivalent
  `wayfire.ini` idle settings (Wayland).
- **Autostart on boot** (systemd service or `.desktop` autostart entry —
  see previous section) instead of `flutter run` from a terminal.
- **Build in `--release` mode**, not debug/profile — debug builds are
  noticeably slower and show a debug banner.
- **Re-verify plugin registration on Linux specifically.** The
  macOS/Linux/Windows runner edits in "One-time setup" step 3 are
  per-platform files; confirm the Linux one (`linux/my_application.cc`) is
  in place, since that's the platform actually running on the Pi.
- **Input devices:** if the Pi kiosk needs touch input rather than a
  mouse, no Dart code changes are required (Flutter's Linux embedder
  handles GTK touch events already), but do test touch-target sizing on
  the actual displays you'll deploy with.
