# Family Registry System 🏛️

**Audichya Gadhiya Brahm Samaj (AGBS), Junagadh**

A modern Flutter mobile application integrated with Supabase backend for managing community family records, member directories, profile photo management, and administrative tracking.

---

## 🎨 Theme & Design Specs
- **Primary Color**: Dark Green (`#0F6E51`)
- **Typography**: Google Fonts (Poppins & Inter)
- **UI Framework**: Flutter Material 3

---

## 🛠️ Technology Stack
- **Frontend**: Flutter
- **Backend & Database**: Supabase (PostgreSQL, Authentication, Row Level Security)
- **Storage**: Supabase Storage (`family-photos` bucket)
- **State Management**: Flutter Riverpod (`flutter_riverpod`)
- **Navigation**: `go_router`

---

## 📁 Feature Structure
```
lib/
├── core/
│   ├── constants/       # App constants & Supabase configuration
│   ├── services/        # Supabase client services
│   └── theme/           # Color palettes & Material3 theme data
└── features/
    ├── auth/            # Sign In, Sign Up & OTP Authentication
    ├── family/          # Family Head & General Details Registration
    ├── members/         # Adding / Managing Family Members
    ├── directory/       # Community Search & Directory
    └── profile/         # User Profile & Admin Settings
```

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.11.0 or higher)
- [Supabase Account](https://supabase.com)

### 2. Setup Project
```bash
# Clone the repository
git clone https://github.com/tejaspatel2255/agbs-family-registry.git

# Navigate to project directory
cd family_registry_system

# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 🔒 License
This project is private and developed for Audichya Gadhiya Brahm Samaj (AGBS), Junagadh.
