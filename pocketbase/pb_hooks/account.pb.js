/// <reference path="../../.pb/pb_data/types.d.ts" />
// REQ-007, REQ-009: account routes the default API does not offer. Authorization and session only.
// Each handler runs isolated: nothing from the top of this file is visible inside it.

routerAdd("POST", "/api/account/change-email", (e) => {
  const body = e.requestInfo().body || {};
  const email = body.email;
  const oldPassword = body.oldPassword;
  if (!email || !oldPassword) {
    throw new BadRequestError("Email and current password are required.");
  }
  const record = $app.findRecordById("users", e.auth.id);
  // The password is checked before the e-mail, so the answer never reveals whether an account exists.
  if (!record.validatePassword(oldPassword)) {
    throw new BadRequestError("Invalid current password.", {
      oldPassword: new ValidationError("validation_invalid_old_password", "Invalid current password."),
    });
  }
  let other = null;
  try {
    other = $app.findAuthRecordByEmail("users", email);
  } catch (_) {
    other = null;
  }
  if (other && other.id !== record.id) {
    throw new BadRequestError("Email already in use.", {
      email: new ValidationError("validation_not_unique", "Email already in use."),
    });
  }
  record.setEmail(email);
  $app.save(record);
  return $apis.recordAuthResponse(e, record, "password", null);
}, $apis.requireAuth("users"));

routerAdd("POST", "/api/account/sign-out-other-devices", (e) => {
  const record = $app.findRecordById("users", e.auth.id);
  record.refreshTokenKey();
  $app.save(record);
  return $apis.recordAuthResponse(e, record, "password", null);
}, $apis.requireAuth("users"));
