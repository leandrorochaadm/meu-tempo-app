import 'package:characters/characters.dart';

import '../../../../core/error/account_field_error_enum.dart';

const int displayNameMinLength = 2; // REQ-002
const int displayNameMaxLength = 50; // REQ-002

/// Checks the display name length, counting characters as the person sees them.
List<AccountFieldErrorEnum> checkDisplayName(String displayName) {
  // REQ-002
  final length = displayName.trim().characters.length;
  if (length < displayNameMinLength || length > displayNameMaxLength) {
    return const [AccountFieldErrorEnum.displayNameLength];
  }
  return const [];
}
