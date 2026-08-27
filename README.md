# AGBS Family Registry System 🏛️

**Audichya Gadhiya Brahm Samaj (AGBS), Junagadh**

A modern, production-grade cross-platform Flutter application integrated with Supabase for managing community family records, member directories, profile photo management, SMS OTP authentication, PDF directory printing, and administrative read-only controls.

---

## 🎨 Design & Features

- **Branding**: Dark Green (`#0F6E51`), Google Fonts (Poppins & Inter), Material 3 styling, customized app launcher icons.
- **Authentication**:
  - **Admin Login**: Password-based authentication for administrators.
  - **Member Authentication**: SMS OTP registration & login via Brevo SMS API.
  - **Member Password Reset**: 3-step OTP password reset flow with single-use tokens & real-time password validation.
- **Family Directory & Admin Read-Only Mode**:
  - **Admin Access**: View-only access to all community family entries without edit/delete privileges.
  - **Interactive Family Modal**: Popup bottom sheet displaying Head of Family (HOF) details and a structured sub-list of family members.
  - **Registered Mobile Number**: HOF registered mobile numbers linked across user profiles.
- **PDF Directory Export & Printing**:
  - Export entire community directory into formatted PDF cards with Poppins Unicode font support.
  - Formatted HOF cards with member sub-tables.
- **Family Record Management**:
  - Full CRUD capabilities for family heads and dependent members.
  - Photo upload support with automatic caching.
  - Search by Name, Family ID, or Address.
  - Row Level Security (RLS) ensuring privacy and access control.

---

## 🛠️ Technology Stack

- **Frontend**: Flutter Web & Mobile (`com.agbsjunagadh.familyregistry`)
- **State Management**: Flutter Riverpod (`flutter_riverpod`)
- **Routing**: `go_router`
- **PDF & Printing**: `pdf` & `printing` with Google Fonts (`poppins`)
- **Backend & DB**: Supabase (PostgreSQL, Auth, RLS, Storage)
- **Edge Functions**: Deno TypeScript (`send-otp`, `verify-otp`, `reset-password`)
- **SMS Gateway**: Brevo SMS API

---

## 🔒 Security & Environment Setup

Environment variables can be provided via `--dart-define` at build time or fallback constants in `lib/core/constants/supabase_constants.dart`.

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://hppmrifkxxlbytvkowdu.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

---

## ⚡ Supabase Edge Functions Deployment

Deploy backend Edge Functions to your Supabase project:

```bash
# 1. Deploy send-otp (Handles SMS dispatching via Brevo)
npx supabase functions deploy send-otp

# 2. Deploy verify-otp (Handles OTP verification & token generation)
npx supabase functions deploy verify-otp

# 3. Deploy reset-password (Handles secure password updates)
npx supabase functions deploy reset-password

# Set Brevo API Key secret
npx supabase secrets set BREVO_API_KEY="your_brevo_api_key"
```

---

## 🚀 Building & Releasing the App

### 1. Android Release APK
```bash
flutter build apk --release
```
*Outputs to `build/app/outputs/flutter-apk/app-release.apk` — ready for direct sharing and installation.*

### 2. Android App Bundle (Google Play Store)
```bash
flutter build appbundle --release
```

### 3. Web Release Build
```bash
flutter build web --release
```

---

## 📜 License
Private repository developed exclusively for **Audichya Gadhiya Brahm Samaj (AGBS), Junagadh**.
