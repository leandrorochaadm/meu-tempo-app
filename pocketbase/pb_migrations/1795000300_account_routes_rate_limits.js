/// <reference path="../pb_data/types.d.ts" />
// Rate limit for the account routes in pb_hooks/account.pb.js (the current password can be guessed
// through the change-email route). Same limit as `*:auth`: 2 requests every 3 seconds.
const LABELS = ["/api/account/change-email", "/api/account/sign-out-other-devices"];

migrate((app) => {
  const settings = app.settings();
  const rules = settings.rateLimits.rules.filter((rule) => !LABELS.includes(rule.label));
  for (const label of LABELS) {
    rules.push({ label: label, maxRequests: 2, duration: 3, audience: "" });
  }
  settings.rateLimits.rules = rules;
  app.save(settings);
}, (app) => {
  const settings = app.settings();
  settings.rateLimits.rules = settings.rateLimits.rules.filter((rule) => !LABELS.includes(rule.label));
  app.save(settings);
});
