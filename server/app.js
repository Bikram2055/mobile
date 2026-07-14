"use strict";

/**
 * Express app for Expense Tracker email + password backend.
 *
 * Exported (not started) so it runs both as a long-lived server (`index.js`,
 * for local/VPS) and as a Vercel serverless function (`api/index.js`).
 *
 * Keeps the Gmail credentials + Firebase Admin service account on the server so
 * nothing sensitive ships inside the app. The app logo is embedded as base64
 * (`logo.js`) so there's no filesystem lookup on serverless hosts.
 *
 * Endpoints:
 *   GET  /health                      liveness check
 *   POST /welcome            (auth)   send welcome email to the signed-in user
 *   POST /connection-request (auth)   email a pending connection's recipient
 *   POST /request-otp                 email a 6-digit password-reset code
 *   POST /reset-password              verify OTP + set new password (Admin SDK)
 */

const crypto = require("crypto");

// Load a local .env when present (no-op in production if dotenv isn't installed).
try {
  require("dotenv").config();
} catch (_) {
  /* dotenv is optional; hosts inject env vars directly. */
}

const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

const { welcomeEmail, otpEmail, connectionRequestEmail } = require("./templates");
const LOGO_BASE64 = require("./logo");

// ---------------------------------------------------------------------------
// Firebase Admin
// ---------------------------------------------------------------------------
// Initialized lazily and defensively so a bad/missing service account can't
// crash the whole function at cold start (which would take down /health too).
let _adminInitError = null;

function ensureAdmin() {
  if (admin.apps.length) return;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw || !raw.trim()) {
    // Falls back to GOOGLE_APPLICATION_CREDENTIALS (a file path) if set.
    admin.initializeApp();
    return;
  }
  // Accept either raw JSON, or a base64-encoded JSON blob. Base64 is the most
  // reliable form for dashboards because it has no quotes/newlines to mangle.
  let jsonStr = raw.trim();
  if (!jsonStr.startsWith("{")) {
    jsonStr = Buffer.from(jsonStr, "base64").toString("utf8").trim();
  }
  const serviceAccount = JSON.parse(jsonStr);
  // Some paste flows leave the PEM newlines as literal "\n"; normalize them so
  // admin.credential.cert() gets a valid key.
  if (typeof serviceAccount.private_key === "string") {
    serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, "\n");
  }
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
}

try {
  ensureAdmin();
} catch (err) {
  _adminInitError = err;
  console.error("Firebase Admin init failed:", err && err.message);
}

// Throws a clean 500-able error if admin couldn't initialize.
function requireDb() {
  ensureAdmin();
  return admin.firestore();
}
function requireAdminAuth() {
  ensureAdmin();
  return admin.auth();
}

// ---------------------------------------------------------------------------
// Email
// ---------------------------------------------------------------------------
const FROM_NAME = "Expense Tracker";
const OTP_TTL_MINUTES = 10;
const OTP_RESEND_COOLDOWN_MS = 60 * 1000;
const OTP_MAX_ATTEMPTS = 5;

// Sanitize credentials: trim the email, and strip ALL whitespace from the app
// password (Gmail app passwords are 16 chars with no spaces; stray spaces or a
// pasted newline otherwise corrupt the SMTP AUTH command).
const gmailUser = () => (process.env.GMAIL_EMAIL || "").trim();
const gmailPass = () => (process.env.GMAIL_APP_PASSWORD || "").replace(/\s+/g, "");

function transporter() {
  return nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: gmailUser(),
      pass: gmailPass(),
    },
  });
}

async function sendMail({ to, subject, html, text }) {
  await transporter().sendMail({
    from: `"${FROM_NAME}" <${gmailUser()}>`,
    to,
    subject,
    text,
    html,
  });
}

// ---------------------------------------------------------------------------
// OTP helpers
// ---------------------------------------------------------------------------
const otpDocId = (email) =>
  crypto.createHash("sha256").update(email).digest("hex");
const hashOtp = (otp, email) =>
  crypto.createHash("sha256").update(`${otp}:${email}`).digest("hex");
const generateOtp = () =>
  String(crypto.randomInt(0, 1000000)).padStart(6, "0");
const normalizeEmail = (value) => String(value || "").trim().toLowerCase();

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------
const app = express();
app.use(cors());
app.use(express.json());

// Verifies the Firebase ID token in `Authorization: Bearer <token>`.
async function requireAuth(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: "Missing auth token." });
  }
  try {
    req.auth = await requireAdminAuth().verifyIdToken(token);
    next();
  } catch (err) {
    return res.status(401).json({ error: "Invalid auth token." });
  }
}

app.get("/health", (_req, res) => {
  const ready = admin.apps.length > 0 && !_adminInitError;
  const body = { ok: true, admin: ready };
  if (!ready && _adminInitError) {
    // Redact any long token-like runs so no key material leaks on this public URL.
    body.reason = String(_adminInitError.message || _adminInitError)
      .replace(/[A-Za-z0-9+/=_-]{16,}/g, "…")
      .slice(0, 200);
  }
  // Safe diagnostics only (lengths/flags, never the values). A correct Gmail
  // app password sanitizes to exactly 16 characters.
  body.gmail = {
    userSet: gmailUser().length > 0,
    passLen: gmailPass().length,
    passLooksValid: gmailPass().length === 16,
  };
  res.json(body);
});

// Serves the app logo so emails can reference it by URL (renders inline in
// Gmail instead of appearing as a broken attachment).
const LOGO_BUFFER = Buffer.from(LOGO_BASE64, "base64");
app.get("/logo.png", (_req, res) => {
  res.set("Content-Type", "image/png");
  res.set("Cache-Control", "public, max-age=604800, immutable");
  res.send(LOGO_BUFFER);
});

// --- Welcome email (called by the app right after sign-up) -----------------
app.post("/welcome", requireAuth, async (req, res) => {
  try {
    const snap = await requireDb().collection("users").doc(req.auth.uid).get();
    const data = snap.data() || {};
    const email = data.email || req.auth.email;
    if (!email) {
      return res.status(400).json({ error: "No email on account." });
    }
    const { subject, html, text } = welcomeEmail({ name: data.displayName || req.auth.name });
    await sendMail({ to: email, subject, html, text });
    res.json({ ok: true });
  } catch (err) {
    console.error("welcome error", err);
    res.status(500).json({ error: "Failed to send welcome email." });
  }
});

// --- Connection request email ----------------------------------------------
app.post("/connection-request", requireAuth, async (req, res) => {
  try {
    const fromUserId = req.auth.uid;
    const toUserId = String((req.body && req.body.toUserId) || "");
    if (!toUserId) {
      return res.status(400).json({ error: "toUserId is required." });
    }

    // Only email if a genuine pending request exists (guards against abuse).
    const reqSnap = await requireDb()
      .collection("users").doc(toUserId)
      .collection("connections").doc(fromUserId)
      .get();
    const reqData = reqSnap.data();
    if (!reqData || reqData.direction !== "incoming" || reqData.status !== "pending") {
      return res.status(400).json({ error: "No pending request found." });
    }

    const [recipientSnap, requesterSnap] = await Promise.all([
      requireDb().collection("users").doc(toUserId).get(),
      requireDb().collection("users").doc(fromUserId).get(),
    ]);
    const recipient = recipientSnap.data() || {};
    const requester = requesterSnap.data() || {};
    if (!recipient.email) {
      return res.status(400).json({ error: "Recipient has no email." });
    }

    const { subject, html, text } = connectionRequestEmail({
      recipientName: recipient.displayName,
      requesterName: requester.displayName,
      requesterEmail: requester.email,
    });
    await sendMail({ to: recipient.email, subject, html, text });
    res.json({ ok: true });
  } catch (err) {
    console.error("connection-request error", err);
    res.status(500).json({ error: "Failed to send connection email." });
  }
});

// --- Forgot-password step 1: request OTP -----------------------------------
app.post("/request-otp", async (req, res) => {
  try {
    const email = normalizeEmail(req.body && req.body.email);
    if (!email || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
      return res.status(400).json({ error: "A valid email is required." });
    }

    // Don't leak whether the account exists.
    let exists = true;
    try {
      await requireAdminAuth().getUserByEmail(email);
    } catch (_) {
      exists = false;
    }
    if (!exists) {
      return res.json({ ok: true });
    }

    const ref = requireDb().collection("passwordOtps").doc(otpDocId(email));
    const existing = await ref.get();
    if (existing.exists) {
      const createdAt = existing.data().createdAt;
      const createdMs = createdAt && createdAt.toMillis ? createdAt.toMillis() : 0;
      if (Date.now() - createdMs < OTP_RESEND_COOLDOWN_MS) {
        return res.status(429).json({
          error: "Please wait a minute before requesting another code.",
        });
      }
    }

    const otp = generateOtp();
    await ref.set({
      email,
      otpHash: hashOtp(otp, email),
      attempts: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000),
    });

    const { subject, html, text } = otpEmail({ otp, minutes: OTP_TTL_MINUTES });
    await sendMail({ to: email, subject, html, text });
    res.json({ ok: true });
  } catch (err) {
    console.error("request-otp error", err);
    res.status(500).json({ error: "Failed to send the reset code." });
  }
});

// --- Forgot-password step 2: verify OTP + set new password -----------------
app.post("/reset-password", async (req, res) => {
  try {
    const body = req.body || {};
    const email = normalizeEmail(body.email);
    const otp = String(body.otp || "").trim();
    const newPassword = String(body.newPassword || "");

    if (!email || !otp) {
      return res.status(400).json({ error: "Email and code are required." });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ error: "Password must be at least 6 characters." });
    }

    const ref = requireDb().collection("passwordOtps").doc(otpDocId(email));
    const snap = await ref.get();
    if (!snap.exists) {
      return res.status(404).json({ error: "No reset request found. Request a new code." });
    }

    const record = snap.data();
    const expiresMs = record.expiresAt && record.expiresAt.toMillis
      ? record.expiresAt.toMillis()
      : 0;
    if (Date.now() > expiresMs) {
      await ref.delete();
      return res.status(410).json({ error: "This code has expired. Request a new one." });
    }
    if ((record.attempts || 0) >= OTP_MAX_ATTEMPTS) {
      await ref.delete();
      return res.status(429).json({ error: "Too many attempts. Request a new code." });
    }
    if (record.otpHash !== hashOtp(otp, email)) {
      await ref.update({ attempts: admin.firestore.FieldValue.increment(1) });
      return res.status(403).json({ error: "Incorrect code. Please try again." });
    }

    let user;
    try {
      user = await requireAdminAuth().getUserByEmail(email);
    } catch (_) {
      await ref.delete();
      return res.status(404).json({ error: "Account not found." });
    }

    await requireAdminAuth().updateUser(user.uid, { password: newPassword });
    await ref.delete();
    res.json({ ok: true });
  } catch (err) {
    console.error("reset-password error", err);
    res.status(500).json({ error: "Failed to reset the password." });
  }
});

module.exports = app;
