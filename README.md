<div align="center">

# 🏛️ AGBS Family Registry System

**Official Community Management Platform for Audichya Gadhiya Brahm Samaj (AGBS), Junagadh**

[![Flutter](https://img.shields.io/badge/Flutter-3.41.2-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Database%20%26%20Auth-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions&logoColor=white)](.github/workflows/build-apk.yml)

---

</div>

## 📌 Executive Summary

The **AGBS Family Registry System** is an enterprise-grade, cross-platform mobile and web application engineered specifically for **Audichya Gadhiya Brahm Samaj (AGBS), Junagadh**. It streamlines community family data management, member directory indexing, secure SMS-based OTP authentication, administrative access controls, profile photo management, and print-ready PDF directory generation.

---

## 🌟 Key Platform Features

### 🔐 Authentication & Access Security
- **Role-Based Access Control (RBAC)**: Distinct user journeys and capabilities for Administrators and General Members.
- **SMS OTP Authentication**: Instant member login and registration powered by Brevo SMS API via Supabase Edge Functions.
- **Secure Password Reset**: 3-step OTP verification workflow enforcing single-use reset tokens and strict password policy constraints.

### 📋 Family Directory Management
- **Structured Data Modeling**: Manage Head of Family (HOF) details alongside dependent family members.
- **Dynamic Search & Filtering**: Instant search by Family ID, Member Name, or Residential Address.
- **Admin Read-Only Portal**: Dedicated admin view ensuring data privacy without edit/delete privileges.

### 📄 PDF Export & Document Generation
- **Printable Community Directory**: Generate high-resolution, paginated PDF directory cards formatted for official print distribution.
- **Custom Font Rendering**: Native integration of Unicode Poppins typography for multilingual accuracy.

### 🖼️ Asset & Media Handling
- **Supabase Storage Integration**: Cloud storage for member and family photos.
- **Optimized Caching**: Cached network images (`cached_network_image`) for low latency and reduced bandwidth consumption.

---

## 🏗️ Architecture & Technology Stack

| Layer | Technology / Package | Purpose |
| :--- | :--- | :--- |
| **Framework** | Flutter (Dart SDK ^3.4.0) | Android & Web Application UI |
| **State Management** | Flutter Riverpod (`flutter_riverpod`) | Reactive, testable application state |
| **Routing** | GoRouter (`go_router`) | Declarative navigation system |
| **Backend & DB** | Supabase (PostgreSQL) | Managed database, RLS policies, & Auth |
| **Serverless Logic** | Deno TypeScript Edge Functions | `send-otp`, `verify-otp`, `reset-password` |
| **SMS Gateway** | Brevo SMS API | Transactional OTP delivery |
| **PDF Generation** | `pdf` & `printing` | Direct client-side PDF rendering |
| **CI/CD** | GitHub Actions | Automated release APK compilation |

---

## 🔒 Security Architecture & Secrets Management

To adhere to DevSecOps best practices, **zero sensitive keys or database credentials** are stored in the codebase.

- Build-time constant injection via `--dart-define` parameters.
- Secrets managed exclusively via **GitHub Repository Secrets**.
- Enforced Row Level Security (RLS) policies at the PostgreSQL database layer.

---

## ⚡ Deployment & Setup Guide

### 1️⃣ Supabase Edge Functions Setup
Deploy backend functions to your Supabase project:

```bash
# Authenticate CLI
npx supabase login

# Link Supabase project
npx supabase link --project-ref <YOUR_PROJECT_ID>

# Deploy Edge Functions
npx supabase functions deploy send-otp
npx supabase functions deploy verify-otp
npx supabase functions deploy reset-password

# Set Brevo SMS API Key
npx supabase secrets set BREVO_API_KEY="your_brevo_api_key"
```

### 2️⃣ GitHub Actions Build Pipeline
GitHub Actions automatically builds production release APKs on pushes to `main`.

Ensure the following **Repository Secrets** are configured under `Settings > Secrets and variables > Actions`:

| Secret Key | Description |
| :--- | :--- |
| `SUPABASE_URL` | Production Supabase Endpoint |
| `SUPABASE_ANON_KEY` | Public Client Anon Key |

---

## 🚀 Building Locally

To generate local release builds with custom environment variables:

### Android Release APK
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

### Web Production Release
```bash
flutter build web --release
```

---

## 📂 Repository Structure

```
family_registry_system/
├── .github/workflows/    # GitHub Actions CI/CD automation
├── android/              # Android native shell & build configurations
├── lib/
│   ├── core/             # Services (Supabase, PDF, Storage), Routing, & Theme
│   └── features/         # Feature modules (Auth, Dashboard, Family, Members)
├── supabase/
│   ├── functions/        # Deno TypeScript Edge Functions
│   └── migrations/       # Database schemas & RLS migration SQLs
├── LICENSE               # MIT License
└── README.md             # Project documentation
```

---

## 📄 License

This project is open-source software licensed under the **[MIT License](LICENSE)**.

Developed for **Audichya Gadhiya Brahm Samaj (AGBS), Junagadh**.
