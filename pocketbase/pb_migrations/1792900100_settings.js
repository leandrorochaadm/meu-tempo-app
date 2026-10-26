/// <reference path="../pb_data/types.d.ts" />
// Batch for the app and rate limits that do not throttle the logged-in user:
// every create inside a batch counts in "*:create", so those rules apply to guests only.
migrate((app) => {
  const settings = app.settings();
  settings.batch.enabled = true;
  settings.batch.maxRequests = 500;
  settings.batch.timeout = 10;
  settings.rateLimits.enabled = true;
  settings.rateLimits.rules = [
    { label: "*:auth", maxRequests: 2, duration: 3, audience: "" },
    { label: "*:create", maxRequests: 20, duration: 5, audience: "@guest" },
    { label: "/api/batch", maxRequests: 3, duration: 1, audience: "@guest" },
    { label: "/api/", maxRequests: 300, duration: 10, audience: "@guest" },
  ];
  app.save(settings);
}, (app) => {
  const settings = app.settings();
  settings.batch.enabled = false;
  settings.rateLimits.rules = [
    { label: "*:auth", maxRequests: 2, duration: 3, audience: "" },
    { label: "*:create", maxRequests: 20, duration: 5, audience: "" },
    { label: "/api/batch", maxRequests: 3, duration: 1, audience: "" },
    { label: "/api/", maxRequests: 300, duration: 10, audience: "" },
  ];
  app.save(settings);
});
