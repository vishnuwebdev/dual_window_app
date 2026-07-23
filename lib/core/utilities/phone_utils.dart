/// South African mobile number normalization/validation, shared by
/// `MockKioskRepository` (storage/lookup) and `LockerGrpcService` (SMS
/// send) — kept as a standalone utility rather than living on either of
/// those classes so neither has to import the other just for this.
class PhoneUtils {
  PhoneUtils._();

  /// Normalizes any of the ways a South African mobile number might end up
  /// in a text field — typed as local `0XXXXXXXXX`, already `+27XXXXXXXXX`
  /// (e.g. because entry fields pre-fill `+27`, see `KioskTextField` call
  /// sites in `lib/pages/customer/`), or with a prefix accidentally
  /// doubled up (`+2727XXXXXXXXX`, `+270XXXXXXXXX`) — into exactly one
  /// canonical form: `+27` followed by the 9-digit subscriber number.
  ///
  /// Idempotent by construction: calling this again on an already-
  /// normalized number returns it unchanged, so every call site (storage,
  /// lookup, SMS send) can normalize defensively without ever risking a
  /// doubled `+27+27...`. Superset of the old `if (phone.startsWith("0"))`
  /// snippet every Android Activity repeated — this also strips a
  /// redundant leading `27` (with or without a `+`) rather than only a
  /// leading `0`.
  static String normalizeToSouthAfrica(String phoneNumber) {
    // Strip everything except digits first. This is what makes a doubled
    // "+27+27..." trivial to collapse — with the '+' characters gone
    // there's nothing to trip up the digit-prefix loop below on.
    var digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Peel off as many redundant country-code ("27") / leading-zero ("0")
    // prefixes as are actually present. A real SA mobile subscriber
    // number always starts with 6, 7, or 8 once those are removed, so
    // it's safe to keep stripping until we see one of those digits.
    while (digits.isNotEmpty && !digits.startsWith(RegExp(r'[678]'))) {
      if (digits.startsWith('27')) {
        digits = digits.substring(2);
      } else if (digits.startsWith('0')) {
        digits = digits.substring(1);
      } else {
        // Doesn't match a known prefix and doesn't start with 6/7/8
        // either — stop rather than eating real digits or looping
        // forever. validatePhoneNumber rejects whatever this produces.
        break;
      }
    }

    return '+27$digits';
  }

  /// Ported from `UtilService.validatePhoneNumber`, but tightened for the
  /// South African kiosk journey: when [isGlobal] is false, the only valid
  /// format is exactly `+27` followed by the 9-digit subscriber number.
  /// In global mode, we still allow a generic `+`-prefixed international
  /// number up to 15 digits.
  static bool validatePhoneNumber(String phoneNumber, bool isGlobal) {
    if (isGlobal) {
      return RegExp(r'^\+[0-9]{1,15}$').hasMatch(phoneNumber);
    }

    return RegExp(r'^\+27[0-9]{9}$').hasMatch(phoneNumber);
  }
}
