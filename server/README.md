# Expense Tracker — Email Server

A tiny Express backend that sends the app's emails (welcome, password-reset OTP,
connection request) via **Gmail** and resets passwords via the **Firebase Admin
SDK**. It exists so credentials never ship inside the APK. Your Firebase project
can stay on the **free Spark plan** — this runs separately on **Vercel**.

Runs two ways from the same code:
- **Vercel serverless** → `api/index.js` (recommended; no cold-start sleep)
- **Local / VPS / Render** → `npm start` (`index.js`)

## Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| GET | `/health` | – | liveness check |
| POST | `/welcome` | Bearer ID token | welcome email after sign-up |
| POST | `/connection-request` | Bearer ID token | email a pending connection's recipient |
| POST | `/request-otp` | – | email a 6-digit reset code |
| POST | `/reset-password` | – | verify OTP + set new password |

## 1. Get the two secrets

**Gmail App Password** — <https://myaccount.google.com/apppasswords> (needs
2-Step Verification). Copy the 16 characters with **no spaces**.

**Firebase service account** — Firebase console → ⚙️ Project settings →
*Service accounts* → **Generate new private key** → download the JSON.

## 2. Deploy to Vercel

You'll set three environment variables:

- `GMAIL_EMAIL` = `trackerexpense29@gmail.com`
- `GMAIL_APP_PASSWORD` = the 16-char app password
- `FIREBASE_SERVICE_ACCOUNT` = the **entire service-account JSON**, pasted as one
  value (Vercel accepts multi-line; `JSON.parse` handles the `\n` in the key)

### Option A — Vercel dashboard (from GitHub)

1. Push this repo to GitHub.
2. Vercel → **Add New… → Project** → import the repo.
3. **Root Directory:** `server`. Framework preset: **Other**. Leave build/output
   empty — the `api/` folder is auto-detected as a serverless function.
4. Add the three environment variables above.
5. **Deploy.** You get a URL like `https://expense-tracker-email.vercel.app`.
6. Verify: open `https://<your-url>/health` → `{"ok":true}`.

### Option B — Vercel CLI

```bash
npm i -g vercel
cd server
vercel link                       # create/link the project (root = this folder)
vercel env add GMAIL_EMAIL production
vercel env add GMAIL_APP_PASSWORD production
vercel env add FIREBASE_SERVICE_ACCOUNT production   # paste the JSON
vercel --prod                     # deploy
```

`vercel.json` routes every path to the function, so `/health`, `/welcome`, etc.
all resolve to the Express app.

## 3. Point the app at the server

Set the base URL (no trailing slash) either by editing
`lib/core/config/app_config.dart` (`_defaultEmailApiBaseUrl`), or at build time:

```bash
flutter run   --dart-define=EMAIL_API_BASE_URL=https://your-url.vercel.app
flutter build apk --release --dart-define=EMAIL_API_BASE_URL=https://your-url.vercel.app
```

While it's empty the app still runs — email features are skipped (welcome /
connection are best-effort; forgot-password shows a "not set up yet" message).

## Local development

```bash
cd server
npm install
cp .env.example .env      # then fill in the three values
npm start                 # → http://localhost:8080
curl http://localhost:8080/health
```

Reach a local server from a phone via your LAN IP (`http://192.168.x.x:8080`)
or a tunnel (`npx ngrok http 8080`).

## Notes

- The logo is embedded as base64 (`logo.js`) — no filesystem lookup, so it works
  on serverless. Regenerate from `assets/icons/app_icon.png` if the icon changes.
- Rotate the Gmail app password if it's ever been shared in plaintext.
- Keep the service-account JSON secret (admin access to your project). It's in
  `.gitignore`; never commit it.
- `/welcome` and `/connection-request` require a valid Firebase ID token, and the
  connection route also verifies a real pending request exists, so they can't be
  used to spam arbitrary addresses.
