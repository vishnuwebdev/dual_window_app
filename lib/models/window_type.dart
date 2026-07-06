/// Identifies which "role" a given native window is playing.
///
/// DESKTOP CONCEPT: every window created by `desktop_multi_window` runs a
/// completely separate Flutter *engine* (its own isolate, its own memory,
/// its own widget tree). They all execute the exact same compiled app
/// (same `main()`), so the only way a window knows what UI to build is by
/// reading the arguments it was launched with. This enum plus [WindowArgs]
/// below is that "which window am I?" signal.
enum AppWindowRole {
  admin,
  customer;

  static AppWindowRole fromName(String? name) {
    return AppWindowRole.values.firstWhere(
      (role) => role.name == name,
      orElse: () => AppWindowRole.admin,
    );
  }
}

/// A small, JSON-serializable payload passed to `WindowConfiguration.arguments`
/// when creating a new window, and read back via `WindowController.arguments`
/// inside that window's own `main()`.
///
/// DESKTOP CONCEPT: `arguments` is a plain [String] (not a Dart object),
/// because it has to cross an engine boundary — it is handed from the
/// parent process to the child engine's native launch code before any Dart
/// code in the child is even running yet. JSON is the simplest robust
/// encoding for that. Keep this payload small and primitive (strings,
/// numbers, bools) — do not try to pass closures, widgets, or complex
/// objects here.
class WindowArgs {
  const WindowArgs({required this.role});

  final AppWindowRole role;

  String encode() => '{"role":"${role.name}"}';

  static WindowArgs decode(String raw) {
    if (raw.trim().isEmpty) {
      // The very first window the OS launches (the Admin window) is
      // started by the OS/`flutter run`, not by our own WindowService, so
      // it never receives our custom arguments. Empty string => Admin.
      return const WindowArgs(role: AppWindowRole.admin);
    }
    // Minimal hand-rolled parsing to avoid pulling in dart:convert for a
    // single field; swap for jsonDecode if you extend this payload.
    final match = RegExp(r'"role"\s*:\s*"(\w+)"').firstMatch(raw);
    return WindowArgs(role: AppWindowRole.fromName(match?.group(1)));
  }
}
