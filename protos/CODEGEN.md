# Generating the Dart gRPC client from service.proto

`service.proto` in this folder is a byte-for-byte copy of
`cnc-dnp-android/app/src/main/proto/service.proto` — the contract the
physical locker unit's `cvmain` gRPC server (`libcvmain_rs.so`, bound to
`0.0.0.0:7777` by default — see the unit's `/cv/config/config.json`) and
your `cv-simulator-rs` setup both need to speak.

`lib/core/grpc/locker_grpc_service.dart` expects the generated output at:

```
lib/generated/service.pb.dart
lib/generated/service.pbgrpc.dart
lib/generated/service.pbenum.dart
```

(`lib/generated/service.pbjson.dart` is also produced but unused —
harmless to leave in place.)

This has already been generated once and committed/left in the working
tree — you only need to redo this if `service.proto` changes. Verified
working with `protoc` 35.1 (Homebrew) and `protoc_plugin` 25.0.0.

## 1. Install protoc (the C++ protobuf compiler)

```bash
# macOS
brew install protobuf

# confirm
protoc --version   # 35.1 confirmed working; anything 3.x+ should do
```

## 2. Install the Dart protoc plugin

```bash
dart pub global activate protoc_plugin
export PATH="$PATH:$HOME/.pub-cache/bin"   # protoc needs `protoc-gen-dart` on PATH
```

## 3. Generate

Run from the `multi-window-app` project root:

```bash
mkdir -p lib/generated
protoc --dart_out=grpc:lib/generated -I protos protos/service.proto
```

Do **not** also compile `google/protobuf/empty.proto` into
`lib/generated/`, even though `service.proto` imports it. This version of
`protoc_plugin` resolves `google.protobuf.Empty` straight to
`package:protobuf/well_known_types/google/protobuf/empty.pb.dart` (see
`service.pbgrpc.dart`'s own imports) rather than generating a local copy.
A separately-generated `lib/generated/google/protobuf/empty.pb.dart`
produces a second, incompatible `Empty` class — `locker_grpc_service.dart`
imports the well-known-types one directly for exactly this reason. If a
future protoc_plugin version changes this behavior, `flutter analyze`
will surface it as a type mismatch on every `Empty()` call site, not a
missing-file error.

Also note: this plugin version keeps each RPC's original snake_case name
on the generated client (`get_slave_firmware`, `unlock_locker`,
`send_sms`, `user_audit`, ...) rather than camelCasing it — match
`locker_grpc_service.dart`'s call sites to whatever
`grep 'ResponseFuture' lib/generated/service.pbgrpc.dart` actually shows
if you regenerate with a different plugin version.

## 4. Install the runtime packages

Declared in `pubspec.yaml` as `grpc: ^5.1.0` and `protobuf: ^6.0.0` —
these versions matter: `protoc_plugin` 25.0.0 emits code (`$_setField`,
`$_clearField`, the `@GrpcServiceName` annotation, etc.) that only exists
in `protobuf` 6.x / `grpc` 5.x, not the older `protobuf: ^2.1.0` /
`grpc: ^3.2.0` this project started with. Just run:

```bash
flutter pub get
```

## 5. Verify

```bash
flutter analyze lib
```

should show no errors in `lib/core/grpc/locker_grpc_service.dart` or
`lib/generated/*.dart` once the generated files exist and the pubspec
versions above are in place. If `analyze` complains about missing
`lib/generated/...` imports, the codegen step above didn't produce the
expected file names/paths — check the actual output of `protoc` and
adjust the imports in `locker_grpc_service.dart` to match.
