# click-n-collect → multi_window_app: migration feasibility

Source analyzed: `za.co.vaultgroup.click_n_collect` (Android, 18 activities + 8 util/service
classes) and the current state of this Flutter project (`multi_window_app`, Admin/Customer
dual-window POC on `desktop_multi_window` + `window_manager` + `screen_retriever`).

## Bottom line

Yes — mostly. The two-window architecture, all UI screens, local storage, REST calls, JSON
handling, and the on-screen keyboard all port to Flutter/Linux cleanly. **One piece does not
port automatically and gates everything else: the locker hardware bridge.** See §1 below before
planning a timeline.

---

## 1. The one hard blocker: the native locker-hardware bridge

The Android app never talks to the locker boards directly. Everything — opening/locking
lockers, reading door states, sending SMS, audit logging, MQTT sync, JWT refresh — goes through
a **local gRPC server on `127.0.0.1:7777`** (`service.proto` / `CommsService`), and that server
is not code in this app. It's started by `CvMainService.start()` (from the vendor AAR
`co.za.vaultgroup:cvmain_android`, bundled as `app/libs/cvmain.aar`), which launches native
binaries baked into the AAR's `nativeLibraryDir`:

- `libcv-cvmaster-rs.so`
- `libcvmain_rs.so`

These are compiled specifically for **Android** (bionic libc, Android's native-library ABI
packaging, Android's serial/USB permission model) and are what actually speaks to the locker
slave boards over a serial connection (`config.json` has `serial.port`, `tcp_listener`,
`tcp_485_passthrough` — this is a serial/RS-485 bridge). The same package also carries
`MqttRunner` and `com.cellvault.libcvmqtt` (JWT refresh, MQTT connect/subscribe, `AuditCodes`).

**Compiled Android `.so` files will not run on Raspberry Pi OS** (aarch64 Linux, glibc, different
serial device paths and permission model). This isn't a Flutter limitation — a Flutter/Dart gRPC
*client* is trivial to write (see §2) — the problem is there is nothing on the Pi side for it to
talk to.

**This needs to be answered by VaultGroup, not by us, before real migration work starts:**

- Do they have (or can they build) a Linux/`aarch64` build of `cvmain`/`cvmaster` that can run
  as a standalone daemon on the Pi and expose the same gRPC service on `127.0.0.1:7777`? If the
  underlying logic is Rust (plausible, given the `-rs.so` naming), cross-compiling to
  `aarch64-unknown-linux-gnu` is realistic vendor-side work — but it is their SDK, their source.
- If not, is the serial/RS-485 protocol to the locker slave boards documented anywhere, so a
  from-scratch Linux-native replacement service could be written against the same physical
  hardware? This is a substantial reverse-engineering/rebuild project, not a port.
- Confirm whether "Raspberry Pi 5" replaces the Android tablet as the thing physically wired to
  the locker boards' serial bus, or whether the tablet stays in place as a headless bridge and
  the Pi only drives the two displays. That changes the shape of this problem entirely.

**Until this is answered, treat the rest of this document as "the app-side plan," not a
guarantee the whole system runs on the Pi.**

---

## 2. What ports cleanly (assuming a gRPC/serial bridge exists on the Pi)

| Android piece | Flutter/Linux equivalent | Notes |
|---|---|---|
| gRPC client to `CommsService` (`service.proto`) | `grpc` + `protobuf` Dart packages, generated from the **same `.proto` file** | Direct port. Same file, same RPCs (`unlock_locker`, `get_locker_states`, `send_sms`, `user_audit`, `get_slave_firmware`, `reboot`, etc.) |
| MQTT (topics: `upload-settings`/`get-settings`/`upload-db`) | `mqtt_client` Dart package | Protocol is portable; the *logic* (JWT refresh, topic routing) currently lives inside the vendor AAR and has no visible source, so it must be re-implemented in Dart from observed behavior, not copied |
| REST calls to `https://saas.vaultgroup-cloud.com/...` (settings sync, unit sign-up/sign-in) with JWT bearer auth | `http`/`dio` + a JWT decode package | Direct port, same endpoints/payloads |
| Local JSON files (`db.json`, `lockerConfig.json`, `sms.json`, `admin.json`, `config.json`, `cvmaster-config/config.json`, `auth.json`, `mq.json`) | `path_provider` for the app-data directory + `dart:io File`, same JSON shapes | Direct port — see §3 for a concurrency caveat |
| `SharedPreferences` (`isGlobal`, `dropoffPinEnabled`, `dropoffPin`, `lockerId`, `terminalId`) | `shared_preferences` package | Direct port |
| UDP beacon listener (`BroadcastListener`, port 2320, `VG.BRIDGE.BEACON`) | `dart:io RawDatagramSocket` | Direct port, plain UDP |
| On-screen keyboard (no physical keyboard on a touchscreen kiosk) | Already built in this project: `KeyboardTextField` / `CustomKeyboard` / `VirtualKeyboardController` | This project's existing solution is arguably *better* than the Android one (Android relied on the system IME) |
| Two physical screens, one process each | Already built: `desktop_multi_window` + `window_manager` + `screen_retriever`, `displays[0]`/`displays[1]` placement | This is exactly what the current POC demonstrates, already documented as Pi-ready in this project's README |
| Inactivity timeouts, auto-return-to-home, countdown dialogs | Plain `Timer`/`Future.delayed` per window | Direct port |
| GIF assets (`android-gif-drawable`) | Flutter's built-in `Image` widget decodes animated GIF natively | No extra package needed |
| Random OTP/PIN generation, phone number regex validation | Plain Dart | Direct port |
| Jackson / kotlinx.serialization / protobuf-lite | `dart:convert` (`jsonEncode`/`jsonDecode`) + generated protobuf Dart classes | Direct port |
| `com.auth0:java-jwt` | Any Dart JWT package, or manual base64/HMAC parsing if the algorithm is simple | Direct port once the token format is confirmed |
| Apache Commons Lang3 | Not a dependency, just inline Dart | N/A |

Everything in this table is standard Flutter desktop work — no exotic plugins, no missing Linux
support.

---

## 3. Not a platform restriction, but a required architecture change: shared state

Today only one screen exists, so Deliver and Collect can never run at the same time —
`DbService`/`LockerService` re-read the same JSON files fresh on every screen open, and there is
never a second reader/writer in flight. On the Pi, **Deliver and Collect will be two permanently
live windows/engines**, plausibly driven by two different people at the same moment, both
reading/writing the same locker-occupancy data and both needing the one physical gRPC/serial
connection to the locker boards.

Recommendation: don't let each window open its own gRPC channel and read/write `db.json`
independently (a direct port of the Android code would do exactly that, and would race). Instead:

- Pick one owner for the gRPC channel, the locker/parcel database, and MQTT/JWT state — either a
  third, hidden "core" engine, or designate one of the two windows as the owner and have the
  other call into it.
- Reuse the `WindowMethodChannel` pattern already in `messaging_service.dart`, but extend it from
  one-way push ("Admin → Customer message") to real request/response RPCs ("Collect window asks
  the owner: does phone+PIN X match a pending item?").
- Consider replacing the flat JSON files with SQLite (`sqlite3`/`drift` package) for the
  parcel/locker database specifically, since it gives real transactions instead of whole-file
  read-then-overwrite, which is unsafe once two windows can call it concurrently.

This is a design decision to make deliberately, not a blocker — just flag it now so it isn't
discovered mid-build.

---

## 4. Screen inventory and where each one goes

Android has 18 activities. Mapped onto two permanent windows:

**Deliver window** (was: Deliver flow, reached from the home screen's "Deliver" button)
- Home/idle screen (deliver side of `MainActivity`)
- `VerifyPinActivity` (optional dropoff-PIN gate, if `dropoffPinEnabled`)
- `PinResetActivity` (reset the dropoff PIN)
- `PrivacyStatementActivity`
- `DeliverInputActivity` (phone number + repeat confirmation)
- `DeliverLockerSelectActivity` (small/medium/large availability + selection)
- `DeliverPlaceParcelActivity` (assigns a random free locker of the chosen size, generates OTP,
  unlocks locker, sends SMS)
- `DeliverDropoffCompleteActivity`

**Collect window** (was: Collect flow, reached from the home screen's "Collect" button)
- Home/idle screen (collect side of `MainActivity`)
- `CollectionInputActivity` (phone + OTP entry, wrong-PIN audit logging)
- `CollectionCompleteActivity` (unlocks matching locker(s), clears the item record)
- `HelpActivity` (resend OTP via phone number lookup — logically belongs with Collect, since it's
  "I lost my PIN")

**Administration** (today: hidden 10-tap-the-logo entry point from the single home screen)
- `AdminLoginActivity`, `AdminOverrideActivity` (manual unlock/clear per locker, SMS template
  edit, unit registration, `cvmain`/`cvmaster` config editing), `AdminResetActivity`
  (admin password reset), `ConfigurationActivity`
- Decision needed: keep the hidden-tap entry point on *both* windows (simplest, matches today's
  behavior), or add a dedicated third admin surface. Either way, admin actions must operate on
  the one shared locker/parcel state from §3, not a per-window copy.

Nothing in this inventory has been skipped — all 18 activities and all 8 `util`/`db` service
classes from the Android source are accounted for above.

---

## 5. Minor Android-isms that don't carry over (easy to drop, not blockers)

- `UtilService.isEmulator()` (checks `Build.BRAND`/`Build.FINGERPRINT`/etc.) — an
  Android-emulator detector used only to decide "am I on a real device with real hardware
  attached." Replace with a simple config flag (e.g. `--dart-define=DEV_MODE=true`) for
  running on a Mac during development vs. the real Pi in production.
- `WRITE_EXTERNAL_STORAGE`/`READ_EXTERNAL_STORAGE` manifest permissions, `InputMethodManager`
  (hide system keyboard) — meaningless on Linux desktop; this project already doesn't need a
  system IME because of its own on-screen keyboard.
- Android `SharedPreferences` API surface itself — swapped for the `shared_preferences` package,
  same key/value model.

None of these affect scope or timeline; they're deleted, not translated.

---

## 6. Suggested next step

Before writing Flutter code for the Deliver/Collect flows, get a straight answer from VaultGroup
on §1 (is there, or can there be, a Linux/`aarch64` `cvmain`/`cvmaster` build, or documented
serial protocol). That answer determines whether this is "port the UI and networking code" (a few
weeks of normal Flutter work, using the table in §2) or "also re-build/port a vendor hardware
driver" (a materially bigger, hardware-integration project that isn't really a Flutter question
at all).
