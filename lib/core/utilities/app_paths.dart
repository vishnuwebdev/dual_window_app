import 'dart:io';

/// Single source of truth for where this app's own local JSON state files
/// live on disk: `config.json`, `db.json`, `auth.json`, `mq.json`. These
/// four are entirely self-contained app state — not to be confused with
/// the *external* cvmain/cvmaster directories (`ConfigService.
/// cvmainConfigDir`/`cvmasterConfigDir`), which point at a different,
/// physical unit's install and have nothing to do with this class.
///
/// `config.json`/`db.json`/`auth.json` live together in a `config/`
/// subdirectory under `Directory.current.path`. `mq.json` lives one level
/// deeper, in `config/mq/` — deliberately mirroring the *external* cvmain
/// layout (`ConfigService.cvmainConfigDir`'s doc comment: "confirmed via
/// SSH: `<dir>/mq/mq.json`"), so the two directory structures line up
/// rather than one being flat and the other nested. Before this class
/// existed, each of `ConfigService`, `MockKioskRepository`,
/// `UnitRegistrationService`, `MqttSyncService`, and `SettingsSyncService`
/// independently built `File('${Directory.current.path}/X.json')` — 6 call
/// sites, no shared constant. That meant relocating these files required
/// hand-editing all 6 in lockstep, with nothing to catch a missed one
/// (mq.json alone was resolved independently in three separate classes).
/// Centralizing here means there's exactly one place left to change if
/// this ever needs to move again.
class AppPaths {
  AppPaths._();

  /// The directory `config.json`/`db.json`/`auth.json` live in. Not
  /// guaranteed to exist — callers that write must call
  /// [ensureDirectoryExists] first; callers that only read can rely on
  /// `File.exists()`/`readAsString()` reporting "missing" the same way
  /// they would against a flat layout.
  static Directory get directory =>
      Directory('${Directory.current.path}/config');

  /// The directory `mq.json` lives in — one level under [directory]. See
  /// the class doc comment for why this is nested rather than a sibling of
  /// `config.json`/`db.json`/`auth.json`.
  static Directory get mqDirectory => Directory('${directory.path}/mq');

  static File get configFile => File('${directory.path}/config.json');
  static File get dbFile => File('${directory.path}/db.json');
  static File get authFile => File('${directory.path}/auth.json');
  static File get mqFile => File('${mqDirectory.path}/mq.json');

  /// Creates [directory] if it doesn't already exist. Call this before any
  /// write against `config.json`/`db.json`/`auth.json` — a fresh install
  /// has no `config/` folder yet, and `File.writeAsString` fails outright
  /// if its parent directory is missing (unlike reads, which just report
  /// the file itself as absent).
  static Future<void> ensureDirectoryExists() async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// Creates [mqDirectory] (and [directory] above it, if needed) if it
  /// doesn't already exist. Call this before writing `mq.json` — same
  /// reasoning as [ensureDirectoryExists], but one level deeper.
  /// `create(recursive: true)` makes both levels in one call, so callers
  /// writing `mq.json` only need this — not [ensureDirectoryExists] too.
  static Future<void> ensureMqDirectoryExists() async {
    if (!await mqDirectory.exists()) {
      await mqDirectory.create(recursive: true);
    }
  }
}
