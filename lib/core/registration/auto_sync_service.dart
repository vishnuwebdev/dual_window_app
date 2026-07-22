import 'dart:async';
import 'dart:io';

import '../config/config_service.dart';
import '../mock/mock_kiosk_repository.dart';
import '../utilities/logging.dart';
import 'settings_sync_service.dart';

/// Automatically pushes this unit's settings/parcel database to VaultGroup's
/// cloud whenever something locally relevant changes — no admin has to
/// press a button. This is the answer to "push to cloud without user
/// intervention": rather than a manual sync screen (removed — see
/// `SettingsSyncService`'s class doc comment for why a visible cloud-sync
/// admin card turned out to be the wrong shape for this), every write path
/// that already exists for a *different* reason (saving the Configuration
/// page, a drop-off/collection mutating `db.json`, an admin editing the
/// SMS template, cvmain/cvmaster rewriting their own config) is watched,
/// and a debounced push follows automatically.
///
/// What's watched, and why each one is already wired to fire without any
/// change on this class's part:
///  - `ConfigService` — a `ChangeNotifier` that already calls
///    `notifyListeners()` on every persisted setting (admin PIN, SMS
///    template, locker mapping/pairing, kiosk mode, ...) *and* every time
///    it reloads `config.json` after another window's engine changed it
///    (see `ConfigService._startWatching`) — so this covers both local
///    edits and external file changes for free.
///  - `MockKioskRepository` — likewise a `ChangeNotifier`, notifying on
///    every parcel drop-off/collection/admin-override mutation and every
///    external `db.json` reload.
///  - `ConfigService.cvmainConfigDir` / `cvmasterConfigDir` — these live
///    *outside* this app's own directory (on the physical unit's real
///    cvmain/cvmaster install), so nothing above catches a change made by
///    cvmain itself rewriting its own `config.json`, or an admin editing
///    it over SSH. This class adds its own `Directory.watch()` on each
///    configured directory to cover that case, re-pointed automatically
///    whenever the directory path itself changes (which *is* covered by
///    the `ConfigService` listener above).
///
/// A single [_debounce] window collapses a burst of changes (e.g.
/// `ConfigurationPage.save()` writing the locker mapping, board counts,
/// and pairing back to back) into exactly one push, the same debouncing
/// pattern `ConfigService`/`MockKioskRepository` already use for their own
/// file-watch reloads.
class AutoSyncService {
  AutoSyncService._();

  static final AutoSyncService instance = AutoSyncService._();

  static const _debounce = Duration(seconds: 4);

  bool _started = false;
  Timer? _debounceTimer;
  StreamSubscription<FileSystemEvent>? _cvmainWatch;
  StreamSubscription<FileSystemEvent>? _cvmasterWatch;
  String? _watchedCvmainDir;
  String? _watchedCvmasterDir;

  /// Call once at startup (see `main.dart`, admin window only — same
  /// "single owner" reasoning as `MqttSyncService`, so there's exactly one
  /// auto-push loop per running app, not one per window). Safe to call
  /// more than once; only the first call does anything.
  void start() {
    if (_started) return;
    _started = true;

    ConfigService().addListener(_onLocalChange);
    ConfigService().addListener(_resyncNativeConfigWatches);
    MockKioskRepository.instance.addListener(_onLocalChange);
    _resyncNativeConfigWatches();

    logger.i('AutoSyncService: started — watching for local changes to auto-push.');
  }

  void _onLocalChange() => _scheduleSync();

  /// (Re)points the raw filesystem watches at whatever
  /// `ConfigService.cvmainConfigDir`/`cvmasterConfigDir` currently point
  /// to. Cheap no-op if neither path actually changed since the last call.
  void _resyncNativeConfigWatches() {
    final cfg = ConfigService();
    if (cfg.cvmainConfigDir != _watchedCvmainDir) {
      _watchedCvmainDir = cfg.cvmainConfigDir;
      _cvmainWatch = _rewatch(_cvmainWatch, _watchedCvmainDir, 'cvmain');
    }
    if (cfg.cvmasterConfigDir != _watchedCvmasterDir) {
      _watchedCvmasterDir = cfg.cvmasterConfigDir;
      _cvmasterWatch = _rewatch(_cvmasterWatch, _watchedCvmasterDir, 'cvmaster');
    }
  }

  StreamSubscription<FileSystemEvent>? _rewatch(
    StreamSubscription<FileSystemEvent>? previous,
    String? dir,
    String label,
  ) {
    previous?.cancel();
    if (dir == null || dir.isEmpty) return null;
    try {
      return Directory(dir).watch().listen((_) => _scheduleSync());
    } catch (e) {
      // Common and expected: the directory doesn't exist yet (e.g. a
      // fresh dev machine with no real cvmain install), or this platform
      // doesn't support recursive directory watching. Either way, this
      // isn't fatal — local `config.json`/`db.json` changes are still
      // watched via the ChangeNotifier listeners above regardless.
      logger.w('AutoSyncService: could not watch $label config directory "$dir": $e');
      return null;
    }
  }

  void _scheduleSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _runSync);
  }

  Future<void> _runSync() async {
    final result = await SettingsSyncService.instance.pushToServer();
    if (result.success) {
      logger.i('AutoSyncService: auto-push succeeded — ${result.message}');
    } else {
      // Expected/quiet until the unit is actually registered — every push
      // attempt before that just logs this once per debounced change
      // rather than surfacing anything to the admin.
      logger.w('AutoSyncService: auto-push failed — ${result.message}');
    }
  }

  /// Stops watching and cancels any pending debounced push. Not currently
  /// called anywhere (this app has no clean-shutdown path for a window's
  /// engine), but provided for symmetry/tests.
  void stop() {
    _debounceTimer?.cancel();
    _cvmainWatch?.cancel();
    _cvmasterWatch?.cancel();
    ConfigService().removeListener(_onLocalChange);
    ConfigService().removeListener(_resyncNativeConfigWatches);
    MockKioskRepository.instance.removeListener(_onLocalChange);
    _started = false;
  }
}
