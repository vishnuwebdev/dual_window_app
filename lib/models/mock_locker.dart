/// Locker size options, matching `Locker.Size` in the Android app
/// (`util/LockerService.kt`): SMALL, MEDIUM, LARGE.
enum LockerSize {
  small,
  medium,
  large;

  String get label => switch (this) {
        LockerSize.small => 'Small',
        LockerSize.medium => 'Medium',
        LockerSize.large => 'Large',
      };
}

enum LockerStatus {
  free,
  inUse;

  String get label => this == LockerStatus.free ? 'Free' : 'In use';
}

/// In-memory stand-in for the Android app's `Locker`/`Item` DB rows.
///
/// This is a visual-only shell: there is no gRPC/backend wiring behind it.
/// Real hardware control (open/close/status) should replace this model with
/// calls into the existing `LockerService`/`LockerBloc` in `core/services`
/// and `bloc/locker`.
class MockLocker {
  MockLocker({
    required this.id,
    required this.size,
    this.status = LockerStatus.free,
  });

  final int id;
  final LockerSize size;
  LockerStatus status;
}

/// Seed data shown on first load of the override dashboard.
List<MockLocker> buildDemoLockers() => [
      MockLocker(id: 1, size: LockerSize.small, status: LockerStatus.inUse),
      MockLocker(id: 2, size: LockerSize.small, status: LockerStatus.free),
      MockLocker(id: 3, size: LockerSize.medium, status: LockerStatus.inUse),
      MockLocker(id: 4, size: LockerSize.medium, status: LockerStatus.free),
      MockLocker(id: 5, size: LockerSize.medium, status: LockerStatus.free),
      MockLocker(id: 6, size: LockerSize.large, status: LockerStatus.inUse),
      MockLocker(id: 7, size: LockerSize.large, status: LockerStatus.free),
      MockLocker(id: 8, size: LockerSize.small, status: LockerStatus.free),
    ];
