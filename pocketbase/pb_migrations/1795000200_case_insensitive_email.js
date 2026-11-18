/// <reference path="../pb_data/types.d.ts" />
// REQ-005: the app signs in and signs up with the normalized e-mail (trimmed, lowercase).
// 1. Legacy accounts saved with uppercase or padded e-mails are normalized, so they still
//    sign in from the app. Two accounts that differ only in case make the unique index
//    refuse the update and the migration stops: resolve them by hand before deploying.
// 2. The unique e-mail index ignores case, so a direct API call cannot create a second
//    account with the same e-mail in another case.
const EMAIL_INDEX = "idx_email__pb_users_auth_";

function emailIndex(collate) {
  return "CREATE UNIQUE INDEX `" + EMAIL_INDEX + "` ON `users` (`email`" + collate + ") WHERE `email` != ''";
}

function replaceEmailIndex(app, collate) {
  const users = app.findCollectionByNameOrId("_pb_users_auth_");
  users.indexes = users.indexes.filter((index) => !index.includes(EMAIL_INDEX)).concat([emailIndex(collate)]);
  app.save(users);
}

migrate((app) => {
  app.db().newQuery("UPDATE users SET email = lower(trim(email)) WHERE email != lower(trim(email))").execute();
  replaceEmailIndex(app, " COLLATE NOCASE");
}, (app) => {
  // The normalized e-mails stay lowercase: the original case is not kept anywhere.
  replaceEmailIndex(app, "");
});
