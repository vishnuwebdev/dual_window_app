/// Data models mirrored from the Android app's `util/LockerService.kt`
/// (`Locker`) and `db/Item.kt` (`Item`) — kept intentionally simple since
/// this is the in-memory mock layer described in `MockKioskRepository`, not
/// a real persistence/gRPC layer yet.
library;

enum LockerSize { small, medium, large }

class Locker {
  Locker({required this.id, required this.size});

  final int id;
  LockerSize size;
}

/// A parcel "ticket": which locker it's in, the phone number it belongs to,
/// and the one-time PIN needed to collect it. Equivalent to the Android
/// `Item` data class.
class LockerItem {
  LockerItem({
    required this.phone,
    required this.pin,
    required this.lockerId,
    required this.creationDate,
  });

  final String phone;
  String pin;
  final int lockerId;
  final DateTime creationDate;
}

/// One row in the Admin Override table. In the normal (unpaired) case
/// there's exactly one row per [Locker] — the flat, pre-paired-mode
/// behavior. In `ConfigService.pairedLockerMode`, each logical locker
/// produces *two* rows, one per physical door (drop-off side and
/// collection side of the pair) — see
/// `MockKioskRepository.getAdminDoorRows`. Both rows for a pair always
/// show the same [occupied] state, since occupancy is tracked once per
/// logical locker, not per physical door.
class AdminDoorRow {
  const AdminDoorRow({
    required this.lockerId,
    required this.label,
    required this.forCollectionSide,
    required this.occupied,
  });

  /// The logical/flat locker id — what `MockKioskRepository`'s occupancy
  /// tracking (`isLockerFree`, `_items`, etc.) keys on. Both rows of a
  /// pair share this same id.
  final int lockerId;

  /// Display label, e.g. `"3"` (unpaired) or `"Pair 2 · Locker 3
  /// (Drop-off)"` (paired).
  final String label;

  /// Which physical door this row represents — only meaningful in paired
  /// mode. Determines which board's gRPC `locker_num` a per-row "Open"
  /// action computes (see `MockKioskRepository.openLockerOnly`).
  final bool forCollectionSide;

  final bool occupied;
}
