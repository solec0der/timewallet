# ⏳ TimeWallet

Personal clone of the "Time Wallet" concept: doom apps (Instagram, YouTube, TikTok, …)
are **hard-blocked** via Apple's Screen Time API. You earn minutes through focus
sessions, steps/exercise, tasks, and time in "good" apps — and spend them **2:1**
to unlock scroll time, metered by actual usage.

## How it works

| Piece | Mechanism |
|---|---|
| Hard block | `ManagedSettings` shield on apps picked with `FamilyActivityPicker` |
| Spend session | Deducts 2× minutes, unshields, `DeviceActivity` usage threshold re-shields after the bought minutes are *actually used* (3 h hard cap) |
| Good-app earning | `DeviceActivity` daily schedule, +5 min credit per 5 min used, capped 60/day |
| Health earning | HealthKit: 5 min per 1000 steps, exercise minutes 1:1 (manual sync button) |
| Focus timer / tasks | In-app, 1:1 / fixed bounties |

## CI / install (no Mac needed)

GitHub Actions (macOS runner) generates the Xcode project with XcodeGen, builds,
dev-signs via App Store Connect API cloud signing, and publishes an OTA install
page to GitHub Pages: **https://solec0der.github.io/timewallet** — open in Safari
on the registered iPhone and tap Install.

### Required repo secrets (Settings → Secrets → Actions)

- `TEAM_ID` — Apple Developer Team ID (developer.apple.com → Membership)
- `ASC_ISSUER_ID` / `ASC_KEY_ID` / `ASC_KEY_P8` — App Store Connect API key (Users & Access → Integrations), p8 file content verbatim
- `DEVICE_UDID` — iPhone UDID (get it phone-only via a UDID profile service, e.g. udid.tech)

Then set repo **variable** `SIGNING_READY=true` to enable the ship job.

### Caveats

- Family Controls (development) entitlement works with a normal paid dev account —
  no Apple approval needed as long as we distribute dev-signed, not App Store.
- Dev-signed builds expire after 1 year; re-run the workflow to refresh.
- Screen Time API quirk: unshielded minutes are metered by usage, so unused
  bought minutes stay available until used, capped at 3 hours per session.
