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

  /// Ported from `UtilService.validatePhoneNumber`: either a local
  /// 10-digit `0XXXXXXXXX` number, or an international `+`-prefixed
  /// number (max 12 digits normally, 15 when [isGlobal] is on). In
  /// practice every call site normalizes before validating now (see
  /// [normalizeToSouthAfrica]), so the input here is almost always
  /// already `+27...` — the local-number branch mainly matters if this
  /// is ever called directly on raw, un-normalized input.
  static bool validatePhoneNumber(String phoneNumber, bool isGlobal) {
    final local = RegExp(r'^0\d{9}$');
    final intl = RegExp(isGlobal ? r'^\+[0-9]{1,15}$' : r'^\+[0-9]{1,12}$');
    return local.hasMatch(phoneNumber) || intl.hasMatch(phoneNumber);
  }
}
