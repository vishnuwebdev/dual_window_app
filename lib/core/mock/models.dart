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
///
/// In `ConfigService.pairedLockerMode` (see the "paired slave board"
/// topology described there), a drop-off physically occupies *two* real
/// locker doors that are wired to the same cavity: [lockerId] is the door
/// the parcel was actually placed behind (the drop-off-side board's
/// door — what physically got unlocked during drop-off), and
/// [collectionLockerId] is its linked partner on the paired
/// collection-side board, which is what actually gets unlocked when the
/// customer collects. Both ids are frozen onto the item at drop-off time
/// (see `MockKioskRepository.addItem`) rather than recomputed from
/// `ConfigService` each time, so an admin editing the board layout later
/// can never retroactively change where an *already dropped-off* parcel's
/// collection door points. `null` outside paired mode — there's only one
/// door, [lockerId] is it, exactly like before this feature existed.
class LockerItem {
  LockerItem({
    required this.phone,
    required this.pin,
    required this.lockerId,
    required this.creationDate,
    this.collectionLockerId,
  });

  final String phone;
  String pin;
  final int lockerId;
  final int? collectionLockerId;
  final DateTime creationDate;
}

/// One row in the Locker Management table — one per physical locker door.
/// Outside paired mode this is exactly one row per [Locker] (unchanged
/// from before pairing existed). In `ConfigService.pairedLockerMode`,
/// [Locker]/`MockKioskRepository.getAllLockers()` already contains every
/// physical door on every board as its own separate entry (drop-off-side
/// and collection-side doors alike), so this is still one row per
/// [Locker] — `forCollectionSide` just flags which physical role that
/// particular door plays, for display and so a paired parcel's two rows
/// share one [occupied] state even though they're different lockers. See
/// `MockKioskRepository.getAdminDoorRows`.
class AdminDoorRow {
  const AdminDoorRow({
    required this.lockerId,
    required this.label,
    required this.forCollectionSide,
    required this.occupied,
  });

  /// The real locker id for this specific physical door — what
  /// `MockKioskRepository.openLockerOnly`/`clearLocker` act on directly,
  /// and what `LockerGrpcService.unlockLocker` receives as-is (no
  /// translation layer — see `MockKioskRepository._unlockPhysicalLocker`).
  final int lockerId;

  /// Display label, e.g. `"3"` (unpaired) or `"Locker 9 (Collection,
  /// paired with 5)"` (paired).
  final String label;

  /// Whether this door is the *collection*-side door of a pair — purely
  /// informational/for styling; opening or clearing a row always acts on
  /// [lockerId] directly regardless of this flag.
  final bool forCollectionSide;

  final bool occupied;
}
