"use strict";

// Privacy policy served at GET /privacy — a public URL for the Play listing.
// Plain self-contained HTML (inline CSS), brand-styled.

const CONTACT_EMAIL = "trackerexpense29@gmail.com";
const EFFECTIVE_DATE = "July 14, 2026";
const APP_NAME = "Expense Tracker";

const PRIVACY_HTML = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${APP_NAME} — Privacy Policy</title>
  <style>
    :root { color-scheme: light; }
    * { box-sizing: border-box; }
    body {
      margin: 0; background: #F6F7FB; color: #1E1E2A;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      line-height: 1.65;
    }
    .wrap { max-width: 760px; margin: 0 auto; padding: 24px 20px 64px; }
    header {
      background: linear-gradient(135deg, #5B5BEF, #2BC0C6);
      color: #fff; border-radius: 20px; padding: 32px 28px; margin-bottom: 28px;
    }
    header h1 { margin: 0 0 6px; font-size: 26px; }
    header p { margin: 0; opacity: .9; }
    h2 { font-size: 19px; margin: 30px 0 10px; }
    p, li { font-size: 15.5px; color: #33333f; }
    a { color: #5B5BEF; }
    ul { padding-left: 22px; }
    .muted { color: #6B7280; font-size: 13.5px; }
    .card { background: #fff; border-radius: 16px; padding: 4px 24px 20px; box-shadow: 0 6px 24px rgba(20,20,40,.06); }
  </style>
</head>
<body>
  <div class="wrap">
    <header>
      <h1>${APP_NAME} — Privacy Policy</h1>
      <p>Effective ${EFFECTIVE_DATE}</p>
    </header>
    <div class="card">
      <p>This Privacy Policy explains how <strong>${APP_NAME}</strong> ("the app", "we")
      collects, uses, and protects your information when you use the mobile application.
      By using the app you agree to this policy.</p>

      <h2>Information we collect</h2>
      <ul>
        <li><strong>Account information</strong> — your name and email address, provided when you create an account.</li>
        <li><strong>Financial entries you create</strong> — expense and income records, including descriptions, amounts, dates, and categories, organized into "books".</li>
        <li><strong>Receipt images</strong> — photos you optionally attach to entries.</li>
        <li><strong>Connections</strong> — when you connect with another user to share books, we store the connection and the other user's email/name to display it.</li>
      </ul>
      <p>We do <strong>not</strong> collect location, contacts, advertising identifiers, or device-tracking data, and we do not sell your data.</p>

      <h2>How we use your information</h2>
      <ul>
        <li>To provide core features: authentication, saving your books and entries, analytics over your own data, and sharing with people you connect to.</li>
        <li>To send transactional emails: a welcome message on sign-up, a one-time code when you request a password reset, and a notification when someone requests to connect with you.</li>
      </ul>

      <h2>Services we use</h2>
      <ul>
        <li><strong>Google Firebase</strong> (Firebase Authentication and Cloud Firestore) stores your account and data securely on Google's infrastructure. See Google's
          <a href="https://firebase.google.com/support/privacy" target="_blank" rel="noopener">Firebase Privacy</a> and
          <a href="https://policies.google.com/privacy" target="_blank" rel="noopener">Google Privacy Policy</a>.</li>
        <li><strong>Email delivery</strong> — transactional emails are sent via Gmail's SMTP service from our backend. Your email address is used only to deliver these messages.</li>
      </ul>

      <h2>Data storage &amp; security</h2>
      <p>Your data is stored in Google Cloud Firestore and transmitted over encrypted (HTTPS/TLS) connections. Passwords are handled by Firebase Authentication and are never stored by us in plain text. Password-reset codes are stored only as a hash with a short expiry.</p>

      <h2>Data retention &amp; deletion</h2>
      <p>Your data is kept while your account is active. You can delete individual books and entries in the app at any time. To delete your entire account and associated data, contact us at
      <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a> and we will remove it.</p>

      <h2>Children</h2>
      <p>${APP_NAME} is not directed to children under 13, and we do not knowingly collect data from them.</p>

      <h2>Changes to this policy</h2>
      <p>We may update this policy from time to time. Material changes will be reflected by updating the effective date above.</p>

      <h2>Contact</h2>
      <p>Questions about this policy or your data? Email <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>.</p>

      <p class="muted">© ${APP_NAME}. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`;

module.exports = PRIVACY_HTML;
