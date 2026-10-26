/// <reference path="../pb_data/types.d.ts" />
// Ownership-only rules: business validation lives in the app domain.
const OWNER = "user = @request.auth.id";
const CREATE_OWN = '@request.auth.id != "" && @request.body.user = @request.auth.id';
const UPDATE_OWN = OWNER + " && @request.body.user:isset = false";
const SELF = "id = @request.auth.id";

const OWN_LIST = "@request.body.list.user = @request.auth.id";
const OWN_PARENT = '(@request.body.parent = "" || @request.body.parent.user = @request.auth.id)';
const OWN_PARENT_UPDATE =
  '(@request.body.parent:isset = false || @request.body.parent = "" || @request.body.parent.user = @request.auth.id)';

// Accepts ids imported from Firestore (and "<id>-<yyyy-mm-dd>" claim ids).
const IMPORTED_ID = {
  name: "id", type: "text", system: true, primaryKey: true, required: true,
  pattern: "^[A-Za-z0-9_-]+$", min: 1, max: 64, autogeneratePattern: "[a-z0-9]{15}",
};

const userField = () => ({
  name: "user", type: "relation", required: true,
  collectionId: "_pb_users_auth_", maxSelect: 1, cascadeDelete: true,
});

const COLLECTION_NAMES = [
  "task_lists", "tasks", "appointments", "time_entries",
  "recurring_tasks", "recurring_task_claims", "day_configs", "active_timers",
];

migrate((app) => {
  // Phase A: collections without rules (locked); rules come after all exist.
  const taskLists = new Collection({
    type: "base",
    name: "task_lists",
    fields: [
      IMPORTED_ID,
      userField(),
      { name: "name", type: "text" },
      { name: "is_default", type: "bool" },
    ],
    indexes: ["CREATE INDEX idx_task_lists_user ON task_lists (user)"],
  });
  app.save(taskLists);

  const tasks = new Collection({
    type: "base",
    name: "tasks",
    fields: [
      IMPORTED_ID,
      userField(),
      { name: "title", type: "text", required: true },
      { name: "list", type: "relation", required: true, collectionId: taskLists.id, maxSelect: 1, cascadeDelete: false },
      { name: "created_at", type: "date" },
      { name: "estimated_minutes", type: "json" },
      { name: "due_date", type: "date" },
      { name: "importance", type: "text" },
      { name: "is_done", type: "bool" },
      { name: "has_children", type: "bool" },
      { name: "spent_minutes", type: "number", onlyInt: true },
      { name: "recurring_task_id", type: "text" },
    ],
    indexes: [
      "CREATE INDEX idx_tasks_user ON tasks (user)",
      "CREATE INDEX idx_tasks_user_is_done_created_at ON tasks (user, is_done, created_at)",
    ],
  });
  app.save(tasks);

  // Self-relation needs the collection id, so it is added after the first save.
  tasks.fields.add(new RelationField({
    name: "parent", collectionId: tasks.id, maxSelect: 1, cascadeDelete: false,
  }));
  tasks.addIndex("idx_tasks_parent", false, "parent", "");
  app.save(tasks);

  app.save(new Collection({
    type: "base",
    name: "appointments",
    fields: [
      IMPORTED_ID,
      userField(),
      { name: "title", type: "text" },
      { name: "list_id", type: "text" },
      { name: "date", type: "date" },
      { name: "start_minute", type: "number", onlyInt: true },
      { name: "duration_minutes", type: "number", onlyInt: true },
      { name: "spent_minutes", type: "number", onlyInt: true },
      { name: "is_done", type: "bool" },
    ],
    indexes: [
      "CREATE INDEX idx_appointments_user ON appointments (user)",
      "CREATE INDEX idx_appointments_user_date_start_minute ON appointments (user, date, start_minute)",
    ],
  }));

  app.save(new Collection({
    type: "base",
    name: "time_entries",
    fields: [
      IMPORTED_ID,
      userField(),
      { name: "target_id", type: "text" },
      { name: "target_type", type: "text" },
      { name: "list_id", type: "text" },
      { name: "origin", type: "text" },
      { name: "minutes", type: "number", onlyInt: true },
      { name: "occurred_at", type: "date" },
    ],
    indexes: [
      "CREATE INDEX idx_time_entries_user ON time_entries (user)",
      "CREATE INDEX idx_time_entries_user_occurred_at ON time_entries (user, occurred_at)",
      "CREATE INDEX idx_time_entries_user_target_id ON time_entries (user, target_id)",
    ],
  }));

  const recurringTasks = new Collection({
    type: "base",
    name: "recurring_tasks",
    fields: [
      IMPORTED_ID,
      userField(),
      { name: "title", type: "text" },
      { name: "list", type: "relation", required: true, collectionId: taskLists.id, maxSelect: 1, cascadeDelete: false },
      { name: "estimated_minutes", type: "number", onlyInt: true },
      { name: "importance", type: "text" },
      { name: "weekdays", type: "json" },
      { name: "created_at", type: "date" },
      { name: "last_generated_on", type: "date" },
    ],
    indexes: ["CREATE INDEX idx_recurring_tasks_user ON recurring_tasks (user)"],
  });
  app.save(recurringTasks);

  app.save(new Collection({
    type: "base",
    name: "recurring_task_claims",
    fields: [
      IMPORTED_ID,
      userField(),
      { name: "recurring_task", type: "relation", required: true, collectionId: recurringTasks.id, maxSelect: 1, cascadeDelete: true },
    ],
    indexes: ["CREATE INDEX idx_recurring_task_claims_user ON recurring_task_claims (user)"],
  }));

  app.save(new Collection({
    type: "base",
    name: "day_configs",
    fields: [
      IMPORTED_ID,
      userField(),
      { name: "available_minutes_per_day", type: "number", onlyInt: true },
      { name: "onboarded", type: "bool" },
    ],
    // One config per user: key of the "update or create" flow.
    indexes: ["CREATE UNIQUE INDEX uq_day_configs_user_upsert ON day_configs (user)"],
  }));

  app.save(new Collection({
    type: "base",
    name: "active_timers",
    fields: [
      IMPORTED_ID,
      userField(),
      { name: "target_id", type: "text" },
      { name: "target_type", type: "text" },
      { name: "list_id", type: "text" },
      { name: "status", type: "text" },
      { name: "started_at", type: "date" },
    ],
    // One active timer per user: key of the "update or create" flow.
    indexes: ["CREATE UNIQUE INDEX uq_active_timers_user_upsert ON active_timers (user)"],
  }));

  // Phase B: rules, now that every collection and field exists.
  const setRules = (name, rules) => {
    const c = app.findCollectionByNameOrId(name);
    c.listRule = OWNER;
    c.viewRule = OWNER;
    c.deleteRule = OWNER;
    c.createRule = rules.create;
    c.updateRule = rules.update;
    app.save(c);
  };

  for (const name of ["task_lists", "appointments", "time_entries", "day_configs", "active_timers"]) {
    setRules(name, { create: CREATE_OWN, update: UPDATE_OWN });
  }
  setRules("tasks", {
    create: CREATE_OWN + " && " + OWN_LIST + " && " + OWN_PARENT,
    update: UPDATE_OWN +
      " && (@request.body.list:isset = false || " + OWN_LIST + ") && " + OWN_PARENT_UPDATE,
  });
  setRules("recurring_tasks", {
    create: CREATE_OWN + " && " + OWN_LIST,
    update: UPDATE_OWN + " && (@request.body.list:isset = false || " + OWN_LIST + ")",
  });
  setRules("recurring_task_claims", {
    create: CREATE_OWN + " && @request.body.recurring_task.user = @request.auth.id",
    update: null, // a claim marker never changes
  });

  // Users: closed sign-up (accounts are created by a superuser), self-only access.
  const users = app.findCollectionByNameOrId("_pb_users_auth_");
  users.createRule = null;
  users.listRule = SELF;
  users.viewRule = SELF;
  users.updateRule = SELF;
  users.deleteRule = SELF;
  users.authToken.duration = 2592000; // 30 days
  users.fields.getByName("password").min = 8;
  users.passwordAuth.enabled = true;
  users.oauth2.enabled = false;
  app.save(users);
}, (app) => {
  for (const name of COLLECTION_NAMES.slice().reverse()) {
    app.delete(app.findCollectionByNameOrId(name));
  }

  const users = app.findCollectionByNameOrId("_pb_users_auth_");
  users.createRule = "";
  users.authToken.duration = 604800; // 7 days, the 0.40.5 default
  users.fields.getByName("password").min = 8;
  app.save(users);
});
