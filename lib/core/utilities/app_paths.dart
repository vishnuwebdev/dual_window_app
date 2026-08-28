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

  /// Five of `config.json`'s eleven settings now live in their own files
  /// instead — admin PIN, drop-off PIN, and SMS template as plain text
  /// (just the raw value, no JSON wrapping), locker sizes and locker pair
  /// mapping as their own JSON files (each holding the same array that
  /// used to sit under `config.json`'s `locker_mapping`/
  /// `locker_pair_mappings` key, now at the file's top level instead of
  /// nested under a key). The other six settings (locker address/backend,
  /// kiosk mode, cvmain/cvmaster config dirs, paired locker mode) stay in
  /// `config.json` — see `ConfigService` for the full read/write/migration
  /// logic; these five are plain siblings of `config.json` in [directory],
  /// not nested like `mq.json` is.
  static File get adminPwFile => File('${directory.path}/admin_pw');
  static File get dropoffPinFile => File('${directory.path}/dropoff_pin');
  static File get smsTemplateFile => File('${directory.path}/sms_template');
  static File get lockerSizesFile =>
      File('${directory.path}/locker_sizes.json');
  static File get lockerPairMappingFile =>
      File('${directory.path}/locker_pair_mapping.json');

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

  /// The directory this app's own compiled executable is running from —
  /// `<bundle>` for a release build (see `linux/CMakeLists.txt`'s
  /// project-specific `scripts/` install rule, which copies
  /// `copy_to_cvmain.sh`/`reset_cvmain.sh` in here as `<this>/scripts/...`
  /// on every `flutter build linux`).
  ///
  /// Deliberately resolved from [Platform.resolvedExecutable] rather than
  /// `Directory.current.path` (unlike [directory] above, which is
  /// correctly install-dir-relative) — this repo's deploy process copies
  /// only the built `bundle/` folder to a unit, and that folder can be
  /// launched from a `cd` into itself or from a `cd` into some parent
  /// directory first (this repo's history has done both at different
  /// times), so `Directory.current.path` isn't a reliable way to find
  /// something that lives *inside* the bundle. The executable's own
  /// location, on the other hand, is fixed relative to the rest of the
  /// bundle no matter how it's launched — `scripts/` installed as a
  /// sibling of the executable will always be at
  /// `<executable's own directory>/scripts/...`.
  static Directory get executableDirectory =>
      File(Platform.resolvedExecutable).parent;

  static Directory get scriptsDirectory =>
      Directory('${executableDirectory.path}/scripts');

  static File get copyToCvmainScript =>
      File('${scriptsDirectory.path}/copy_to_cvmain.sh');
  static File get resetCvmainScript =>
      File('${scriptsDirectory.path}/reset_cvmain.sh');
}
