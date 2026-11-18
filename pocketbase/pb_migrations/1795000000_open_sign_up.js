/// <reference path="../pb_data/types.d.ts" />
// REQ-001: open sign-up. Creating a user is an authentication route, an accepted
// exception to the "nothing without login" rule. Other users rules stay self-only.
migrate((app) => {
  const users = app.findCollectionByNameOrId("_pb_users_auth_");
  users.createRule = "";
  app.save(users);
}, (app) => {
  const users = app.findCollectionByNameOrId("_pb_users_auth_");
  users.createRule = null;
  app.save(users);
});
