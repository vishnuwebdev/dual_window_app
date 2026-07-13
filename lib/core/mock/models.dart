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
