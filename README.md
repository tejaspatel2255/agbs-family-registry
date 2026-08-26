# AGBS Family Registry System 🏛️

**Audichya Gadhiya Brahm Samaj (AGBS), Junagadh**

A modern, cross-platform Flutter application integrated with Supabase for managing community family records, member directories, profile photo management, SMS OTP authentication, and administrative controls.

---

## 🎨 Design & Features

- **Branding**: Dark Green (`#0F6E51`), Google Fonts (Poppins & Inter), Material 3 styling.
- **Authentication**:
  - **Admin Login**: Secure password authentication for administrators.
  - **Member Authentication**: SMS OTP registration & login via Brevo SMS.
  - **Member Password Reset**: 3-step OTP password reset flow with 10-minute single-use tokens & real-time password strength validation.
- **Family Record Management**:
  - Full CRUD capabilities for family heads and members.
  - Photo upload support with automatic caching.
  - Search by Name, Family ID, or Address.
  - Row Level Security (RLS) ensuring privacy and access control.

---

## 🛠️ Technology Stack

- **Frontend**: Flutter (Web, Android, iOS, Windows, macOS)
- **State Management**: Flutter Riverpod (`flutter_riverpod`)
- **Routing**: `go_router`
- **Backend & DB**: Supabase (PostgreSQL, Auth, RLS, Storage)
- **Edge Functions**: Deno TypeScript (`send-otp`, `verify-otp`, `reset-password`)
- **SMS Gateway**: Brevo SMS API

---

## 🔒 Security & Environment Setup

Sensitive environment credentials (such as Supabase Anon Keys and API URLs) are kept out of Git via `.gitignore`.

### Initial Setup:
1. Copy `supabase_constants.template.dart` to create your local `supabase_constants.dart`:
   ```bash
   cp lib/core/constants/supabase_constants.template.dart lib/core/constants/supabase_constants.dart
   ```
2. Open `lib/core/constants/supabase_constants.dart` and paste your Supabase Project URL and Anon Key:
   ```dart
   class SupabaseConstants {
     static const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   }
   ```

---

## ⚡ Supabase Edge Functions Deployment

Deploy all 3 backend Edge Functions to your Supabase project:

```bash
# 1. Deploy send-otp (Handles SMS dispatching via Brevo)
npx supabase functions deploy send-otp

# 2. Deploy verify-otp (Handles OTP verification & token generation)
npx supabase functions deploy verify-otp

# 3. Deploy reset-password (Handles secure password updates)
npx supabase functions deploy reset-password
```

Set required environment variables in Supabase Dashboard (or via CLI):
```bash
npx supabase secrets set BREVO_API_KEY="your_brevo_api_key"
```

---

## 🚀 Building & Releasing the App

### 1. Web Release Build
```bash
flutter build web --release
```
*Outputs to `build/web/` — ready to host on Vercel, Netlify, Firebase, or any web server.*

### 2. Android Release Builds
```bash
# Direct APK (for testing or direct sharing)
flutter build apk --release

# Android App Bundle (for Google Play Store upload)
flutter build appbundle --release
```

### 3. Windows Desktop Build
```bash
flutter build windows --release
```

---

## 📜 License
Private repository developed exclusively for **Audichya Gadhiya Brahm Samaj (AGBS), Junagadh**.
