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

## 🔒 Security & Environment Setup
To protect sensitive API keys, `lib/core/constants/supabase_constants.dart` is excluded from version control (`.gitignore`).

1. Copy the template file:
   ```bash
   cp lib/core/constants/supabase_constants.template.dart lib/core/constants/supabase_constants.dart
   ```
2. Open `lib/core/constants/supabase_constants.dart` and insert your actual Supabase URL and Anon Key.

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.11.0 or higher)
- [Supabase Account](https://supabase.com)

### 2. Run the App
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

## 📜 License
This project is private and developed for Audichya Gadhiya Brahm Samaj (AGBS), Junagadh.
