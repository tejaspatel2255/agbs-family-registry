# AGBS Family Registry System 🏛️

**Audichya Gadhiya Brahm Samaj (AGBS), Junagadh**

A modern, production-grade cross-platform Flutter application integrated with Supabase for managing community family records, member directories, profile photo management, SMS OTP authentication, PDF directory printing, and administrative controls.

---

## ✨ Features

- **Authentication**
  - Admin login with password-based auth
  - Member registration & login via **SMS OTP** (Brevo API)
  - 3-step OTP-based password reset flow with single-use tokens
- **Family Directory**
  - Full CRUD for family heads (Head of Family) and dependent members
  - Admin read-only view of all community entries
  - Interactive bottom-sheet with HOF details & family member list
  - Search by Name, Family Code, or Address
- **PDF Export & Printing**
  - Export full community directory to formatted PDF with Poppins fonts
  - HOF cards with member sub-tables and pagination
- **Photo Management**
  - Profile & member photo upload to Supabase Storage
  - Automatic image caching via `cached_network_image`
- **Security**
  - Row Level Security (RLS) on all Supabase tables
  - All secrets injected at build time via `--dart-define` (GitHub Actions Secrets)
  - **No credentials hardcoded in source code**

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Android, Web) |
| State Management | Flutter Riverpod |
| Navigation | go_router |
| Backend & Database | Supabase (PostgreSQL + Auth + Storage + RLS) |
| Edge Functions | Deno TypeScript (`send-otp`, `verify-otp`, `reset-password`) |
| SMS Gateway | Brevo SMS API |
| PDF & Printing | `pdf` + `printing` packages |
| Fonts | Google Fonts (Poppins, Inter) |
| CI/CD | GitHub Actions |

---

## 🔒 Environment Setup (Credentials)

> ⚠️ **Never hardcode credentials in source code.** All secrets are managed via GitHub Repository Secrets and injected at build time.

### Required GitHub Secrets

Go to: `GitHub Repo → Settings → Secrets and Variables → Actions`

| Secret Name | Value |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon/public key |

### Local Development Build (optional)

To build locally with credentials, pass them explicitly:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project-id.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key_here
```

---

## ⚡ Supabase Edge Functions Deployment

```bash
# Login to Supabase CLI
npx supabase login

# Link your project
npx supabase link --project-ref your-project-id

# Deploy Edge Functions
npx supabase functions deploy send-otp
npx supabase functions deploy verify-otp
npx supabase functions deploy reset-password

# Set Brevo SMS API key as Supabase secret
npx supabase secrets set BREVO_API_KEY="your_brevo_api_key"
```

---

## 🚀 CI/CD — Automated APK Build (GitHub Actions)

Every push to `main` automatically:
1. Checks out the repository
2. Sets up Java 17 + Flutter 3.41.2
3. Injects `SUPABASE_URL` and `SUPABASE_ANON_KEY` from GitHub Secrets
4. Builds a release APK with `flutter build apk --release`
5. Uploads the APK as a downloadable artifact

**Download the latest APK:**  
`GitHub Repo → Actions → (latest run) → Artifacts → release-apk`

---

## 🏗️ Manual Build Commands

```bash
# Android Release APK
flutter build apk --release

# Android App Bundle (Google Play)
flutter build appbundle --release

# Web Release
flutter build web --release
```

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/         # Supabase config (values from --dart-define)
│   ├── router/            # go_router navigation
│   ├── services/          # Supabase, Storage, PDF services
│   └── theme/             # App colors & theme
├── features/
│   ├── auth/              # Login, Signup, OTP, Forgot Password screens
│   ├── dashboard/         # Admin & Member dashboards
│   ├── family/            # Family CRUD, form, model, repository
│   ├── members/           # Family member model
│   ├── splash/            # Splash screen
│   └── welcome/           # Welcome screen
└── main.dart
supabase/
├── functions/             # Edge Functions (send-otp, verify-otp, reset-password)
└── migrations/            # Database migration SQL files
```

---

## 📜 License

Private repository developed exclusively for **Audichya Gadhiya Brahm Samaj (AGBS), Junagadh**.  
All rights reserved © 2026 AGBS, Junagadh.
