/// Log levels — mirrors `LogConstants.kt`'s `LOG_LEVEL_*` constants
/// verbatim (`za.co.vaultgroup.click_n_collect.util.LogConstants`, in the
/// cnc-dnp-android repo).
class AuditLogLevel {
  AuditLogLevel._();

  static const info = 'info';
  static const warning = 'warning';
  static const error = 'error';
  static const fatal = 'fatal';
}

/// UNCONFIRMED — mirrors the `LOG_PRIORITY_*` constants referenced
/// throughout the Android app (`LOG_PRIORITY_LOW`, `_MEDIUM`, `_NORMAL`,
/// `_VV_HIGH`, `_VVV_HIGH`), which live in
/// `com.cellvault.libcvmqtt.AuditCodes` — a private VaultGroup dependency
/// resolved from Gradle, not vendored in the Android repo's source, so its
/// exact wire values couldn't be read directly. The values below are
/// inferred from the naming pattern, not confirmed against the real
/// library. If audit events show up with the wrong priority (or get
/// rejected) on the VaultGroup dashboard, this is the first place to
/// check — pull the real values from `libcvmqtt`'s `AuditCodes` class on
/// the Android side and correct these to match.
class AuditLogPriority {
  AuditLogPriority._();

  static const low = 'low';
  static const medium = 'medium';
  static const normal = 'normal';
  static const veryHigh = 'vv_high';
  static const veryVeryHigh = 'vvv_high';
}

/// Numeric audit codes — mirrors `LogConstants.kt` verbatim (values copied
/// directly from cnc-dnp-android's source, not inferred), so audit events
/// from this app land in the same code space VaultGroup's platform already
/// understands from the Android kiosk. Only a subset of these are
/// currently wired up (see `deliver_place_parcel_page.dart`,
/// `collection_complete_page.dart`, `locker_management_page.dart`) — add
/// calls at other call sites using these same codes as needed.
class AuditCodes {
  AuditCodes._();

  static const appStarted = 1;
  static const startingServer = 2;

  static const findFreeLockerSuccess = 10;
  static const findFreeLockerInvalidSize = 11;
  static const findFreeLockerDbReadingFailure = 12;

  static const dropoffStarted = 30;
  static const dropoffSuccess = 31;
  static const dropoffInvalidLocker = 32;
  static const dropoffInvalidCellNumber = 33;
  static const dropoffInvalidPinNumber = 34;
  static const dropoffCellNumberAlreadyRegistered = 35;
  static const dropoffLockerInUse = 36;
  static const dropoffUnlockingFailure = 37;
  static const dropoffDbReadingFailure = 38;
  static const dropoffDbWritingFailure = 39;

  static const pickupStarted = 50;
  static const pickupSuccess = 51;
  static const pickupInvalidPin = 52;
  static const pickupInvalidCellNumber = 53;
  static const pickupNotAvailable = 54;
  static const pickupWrongPin = 55;
  static const pickupUnlockingFailure = 56;
  static const pickupDbReadingFailure = 57;
  static const pickupDbWritingFailure = 58;

  static const pinRequestCellNumberNotRegistered = 70;
  static const pinRequestSendingSms = 71;
  static const pinRequestSmsSendingSuccess = 72;
  static const pinRequestSmsSendingFailure = 73;
  static const pinRequestDbReadingFailure = 74;

  static const cellNumberRegistrationCheck = 90;
  static const cellNumberRegistrationCheckSuccess = 91;
  static const cellNumberRegistrationCheckDbReadingFailure = 92;

  static const adminUnlockStarting = 110;
  static const adminUnlockSuccess = 111;
  static const adminUnlockFailure = 112;
  static const adminUnlockTokenValidationError = 113;
  static const adminUnlockTokenValidationFailure = 114;
  static const adminUnlockDbClearingFailure = 115;

  static const adminPasswordChangeSuccess = 130;
  static const adminPasswordChangeFailure = 131;
  static const adminPasswordChangeTokenValidationError = 132;
  static const adminPasswordChangeTokenValidationFailure = 133;
}
