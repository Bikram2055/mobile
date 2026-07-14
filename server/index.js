"use strict";

// Local / long-lived server entry (VPS, Render, `npm start`).
// Vercel uses api/index.js instead, which imports the same app.
const app = require("./app");

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log(`Expense Tracker email server listening on :${port}`);
});
