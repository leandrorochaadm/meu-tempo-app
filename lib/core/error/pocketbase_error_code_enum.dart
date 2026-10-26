/// Error codes sent by the PocketBase server that the app recognizes. The
/// spelling from outside lives only inside this enum.
enum PocketBaseErrorCodeEnum {
  notUnique('validation_not_unique'),

  /// Repeated record id on `create` (checked in step 02, proof P5).
  duplicateId('validation_pk_invalid'),
  batchRequestFailed('batch_request_failed'),
  unknown('unknown');

  const PocketBaseErrorCodeEnum(this.apiValue);

  /// Spelling used by the server.
  final String apiValue;

  /// Null, empty or unrecognized code returns [unknown].
  static PocketBaseErrorCodeEnum fromApi(String? raw) {
    for (final code in values) {
      if (code != unknown && code.apiValue == raw) return code;
    }
    return unknown;
  }

  /// Codes that mean "this record or key already exists".
  bool get isConflict => this == notUnique || this == duplicateId;
}
