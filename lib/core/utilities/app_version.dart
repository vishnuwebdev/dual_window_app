import 'package:flutter/services.dart' show rootBundle;

/// The app's own version, read from `pubspec.yaml`'s `version:` field at
/// runtime instead of being hardcoded — see `LockerManagementPage`, which
/// used to show a literal `'Version 0.1.0'` that had quietly drifted out
/// of sync with `pubspec.yaml` (already at `1.0.0+1`) since nothing forced
/// the two to agree.
///
/// Reads `pubspec.yaml` as a plain bundled asset (see the `assets:` list
/// in `pubspec.yaml` itself) rather than via a version-info plugin —
/// that works identically on every platform this app targets, including
/// Linux desktop, with no native plugin registration involved.
class AppVersion {
  AppVersion._();

  static String? _cachedRaw;

  /// The exact text after `version:` in `pubspec.yaml` — e.g. `'1.0.0+1'`.
  /// Cached after the first successful read, since `pubspec.yaml` doesn't
  /// change while the app is running. Falls back to an empty string if the
  /// asset is missing or malformed, so a broken read never crashes the UI.
  static Future<String> raw() async {
    final cached = _cachedRaw;
    if (cached != null) return cached;

    try {
      final contents = await rootBundle.loadString('pubspec.yaml');
      final match =
          RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(contents);
      final version = match?.group(1) ?? '';
      _cachedRaw = version;
      return version;
    } catch (_) {
      return '';
    }
  }

  /// Just the semantic-version part before the `+build` suffix — e.g.
  /// `'1.0.0'` out of `'1.0.0+1'`. What `LockerManagementPage` shows,
  /// matching the plain "Version X.Y.Z" style the old hardcoded text used.
  static Future<String> name() async {
    final version = await raw();
    final plusIndex = version.indexOf('+');
    return plusIndex == -1 ? version : version.substring(0, plusIndex);
  }
}
