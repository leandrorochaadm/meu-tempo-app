/// PocketBase collection names (schema in `pocketbase/pb_migrations`).
abstract final class PbCollections {
  static const users = 'users';
  static const taskLists = 'task_lists';
  static const tasks = 'tasks';
  static const appointments = 'appointments';
  static const timeEntries = 'time_entries';
  static const recurringTasks = 'recurring_tasks';
  static const recurringTaskClaims = 'recurring_task_claims';
  static const dayConfigs = 'day_configs';
  static const activeTimers = 'active_timers';
}

/// PocketBase field names. Shared fields appear once.
abstract final class PbFields {
  // common
  static const id = 'id';
  static const user = 'user';
  static const createdAt = 'created_at';

  // users
  static const email = 'email';

  // task_lists
  static const name = 'name';
  static const isDefault = 'is_default';

  // tasks
  static const title = 'title';
  static const list = 'list';
  static const parent = 'parent';
  static const estimatedMinutes = 'estimated_minutes';
  static const dueDate = 'due_date';
  static const importance = 'importance';
  static const isDone = 'is_done';
  static const hasChildren = 'has_children';
  static const spentMinutes = 'spent_minutes';
  static const recurringTaskId = 'recurring_task_id';
  static const listId = 'list_id';

  // appointments
  static const date = 'date';
  static const startMinute = 'start_minute';
  static const durationMinutes = 'duration_minutes';

  // time_entries
  static const targetId = 'target_id';
  static const targetType = 'target_type';
  static const origin = 'origin';
  static const minutes = 'minutes';
  static const occurredAt = 'occurred_at';

  // recurring_tasks
  static const weekdays = 'weekdays';
  static const lastGeneratedOn = 'last_generated_on';

  // recurring_task_claims
  static const recurringTask = 'recurring_task';

  // day_configs
  static const availableMinutesPerDay = 'available_minutes_per_day';
  static const onboarded = 'onboarded';

  // active_timers
  static const status = 'status';
  static const startedAt = 'started_at';

  /// Update modifier that adds to a number field (e.g. `spent_minutes+`).
  static String increment(String field) => '$field+';
}
