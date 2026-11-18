/// <reference path="../pb_data/types.d.ts" />
// REQ-004: privacy policy acceptance date on the user, stamped by the server at
// creation (autodate); the app never sends it and it never changes on update.
migrate((app) => {
  const users = app.findCollectionByNameOrId("_pb_users_auth_");
  users.fields.add(new AutodateField({ name: "privacy_policy_accepted_at", onCreate: true, onUpdate: false }));
  app.save(users);
}, (app) => {
  const users = app.findCollectionByNameOrId("_pb_users_auth_");
  users.fields.removeByName("privacy_policy_accepted_at");
  app.save(users);
});
