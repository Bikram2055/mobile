"use strict";

/**
 * Branded HTML email templates for Expense Tracker.
 *
 * The app logo is attached inline by index.js with `cid: "applogo"`, so every
 * template references it via `src="cid:applogo"` — no external hosting needed.
 */

const BRAND = {
  name: "Expense Tracker",
  primary: "#5B5BEF",
  accent: "#2BC0C6",
  text: "#1E1E2A",
  muted: "#6B7280",
  bg: "#F6F7FB",
  card: "#FFFFFF",
};

/**
 * Wraps body content in the shared responsive shell (header with logo +
 * footer). `preheader` is the hidden inbox-preview line.
 */
function layout({ preheader, body }) {
  return `<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="color-scheme" content="light">
    <title>${BRAND.name}</title>
  </head>
  <body style="margin:0;padding:0;background:${BRAND.bg};">
    <span style="display:none!important;visibility:hidden;opacity:0;color:transparent;height:0;width:0;overflow:hidden;">${preheader}</span>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${BRAND.bg};padding:24px 12px;">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:${BRAND.card};border-radius:20px;overflow:hidden;box-shadow:0 8px 30px rgba(20,20,40,0.08);">
            <tr>
              <td style="background:linear-gradient(135deg, ${BRAND.primary}, ${BRAND.accent});padding:28px 32px;">
                <table role="presentation" cellpadding="0" cellspacing="0">
                  <tr>
                    <td style="padding-right:12px;" valign="middle">
                      <img src="cid:applogo" width="40" height="40" alt="${BRAND.name}" style="display:block;border-radius:10px;">
                    </td>
                    <td valign="middle">
                      <span style="font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;font-size:20px;font-weight:700;color:#ffffff;">${BRAND.name}</span>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr>
              <td style="padding:32px;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:${BRAND.text};">
                ${body}
              </td>
            </tr>
            <tr>
              <td style="padding:20px 32px;border-top:1px solid #EEF0F6;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
                <p style="margin:0;font-size:12px;color:${BRAND.muted};line-height:18px;">
                  You received this email because an action was taken with your ${BRAND.name} account.
                  If this wasn't you, you can safely ignore this message.
                </p>
                <p style="margin:8px 0 0;font-size:12px;color:${BRAND.muted};">© ${BRAND.name}</p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}

function button(label, note) {
  return `<div style="margin:24px 0;">
    <span style="display:inline-block;background:${BRAND.primary};color:#ffffff;font-weight:700;font-size:15px;padding:14px 26px;border-radius:14px;">${label}</span>
    ${note ? `<div style="margin-top:8px;font-size:12px;color:${BRAND.muted};">${note}</div>` : ""}
  </div>`;
}

/** Welcome email sent after a new account is created. */
function welcomeEmail({ name }) {
  const first = (name || "there").split(" ")[0];
  return {
    subject: `Welcome to ${BRAND.name}, ${first}! 🎉`,
    html: layout({
      preheader: `Your ${BRAND.name} account is ready.`,
      body: `
        <h1 style="margin:0 0 12px;font-size:22px;font-weight:800;">Welcome aboard, ${escapeHtml(first)}!</h1>
        <p style="margin:0 0 16px;font-size:15px;line-height:24px;color:#3A3A4A;">
          Your ${BRAND.name} account is all set. You can now create books, log expenses and income
          by category, and see where your money goes with interactive analytics.
        </p>
        <ul style="margin:0 0 8px;padding-left:20px;font-size:15px;line-height:26px;color:#3A3A4A;">
          <li>📚 Organise spending into books</li>
          <li>🏷️ Tag entries with categories (or make your own)</li>
          <li>📊 Explore doughnut, radial &amp; bar charts</li>
          <li>🤝 Connect with others to share books</li>
        </ul>
        ${button("Start tracking")}
        <p style="margin:16px 0 0;font-size:14px;color:${BRAND.muted};">Happy budgeting! 💜</p>
      `,
    }),
  };
}

/** One-time passcode email for the forgot-password flow. */
function otpEmail({ otp, minutes }) {
  return {
    subject: `Your ${BRAND.name} password reset code`,
    html: layout({
      preheader: `Your password reset code is ${otp}.`,
      body: `
        <h1 style="margin:0 0 12px;font-size:22px;font-weight:800;">Reset your password</h1>
        <p style="margin:0 0 20px;font-size:15px;line-height:24px;color:#3A3A4A;">
          Use the code below to reset your ${BRAND.name} password. It expires in
          <strong>${minutes} minutes</strong>.
        </p>
        <div style="text-align:center;margin:8px 0 20px;">
          <div style="display:inline-block;background:${BRAND.bg};border:1px dashed ${BRAND.primary};border-radius:16px;padding:18px 28px;">
            <span style="font-family:'Courier New',monospace;font-size:34px;font-weight:800;letter-spacing:10px;color:${BRAND.primary};">${otp}</span>
          </div>
        </div>
        <p style="margin:0;font-size:13px;line-height:20px;color:${BRAND.muted};">
          If you didn't request a password reset, ignore this email — your password stays unchanged.
          Never share this code with anyone.
        </p>
      `,
    }),
  };
}

/** Notification email when someone requests to connect. */
function connectionRequestEmail({ recipientName, requesterName, requesterEmail }) {
  const first = (recipientName || "there").split(" ")[0];
  return {
    subject: `${requesterName || "Someone"} wants to connect on ${BRAND.name}`,
    html: layout({
      preheader: `${requesterName || "Someone"} sent you a connection request.`,
      body: `
        <h1 style="margin:0 0 12px;font-size:22px;font-weight:800;">New connection request</h1>
        <p style="margin:0 0 16px;font-size:15px;line-height:24px;color:#3A3A4A;">
          Hi ${escapeHtml(first)}, <strong>${escapeHtml(requesterName || "A user")}</strong>
          ${requesterEmail ? `(${escapeHtml(requesterEmail)})` : ""} wants to connect with you on
          ${BRAND.name} so you can share books.
        </p>
        <p style="margin:0 0 4px;font-size:15px;line-height:24px;color:#3A3A4A;">
          Open the app and head to <strong>Profile → Connections</strong> to accept or decline.
        </p>
        ${button("Review request", "Open Expense Tracker on your device")}
      `,
    }),
  };
}

function escapeHtml(value) {
  return String(value || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

module.exports = { welcomeEmail, otpEmail, connectionRequestEmail, BRAND };
