# Study Hub — Professional Self-Study Flutter Application 🎓

A cross-platform Flutter application (Android, Windows Desktop, Web) replacing the legacy web guide with a modern, high-performance, and feature-rich Self-Study Hub.

---

## ✨ Features & Capabilities

- 🔐 **Secure Password-Protected Catalog:**
  - Implements client-side decryption compatible with the original `guide.html` data (`PBKDF2` with SHA-256 600,000 rounds, `HKDF`, and `AES-256-GCM`).
  - Safe in-memory key storage with optional "Remember on this device" support.
  - "Explore Sample / Offline Courses" mode for immediate demo access.

- 📚 **Comprehensive Course & Subject Management:**
  - Dynamic subject cards with subject category hue indicators.
  - Unit drill-down with lecture counts, individual lecture tracking, and completion checkmarks.
  - Real-time search across subject names, units, lecture titles, tags, and lecture numbers (`L-1`, `Unit 2`, etc.).

- 📊 **Study Progress Tracker:**
  - Mark lectures as completed or in progress with interactive checkmarks.
  - Per-subject progress bars and percentage calculation.
  - Top stats header showing overall learning progress and finished lectures count.

- 🎬 **Video Playback & External Tools:**
  - Direct video player modal dialog with URL decryption on-demand.
  - Playback speed switcher (0.75x, 1.0x, 1.25x, 1.5x, 2.0x).
  - Quick action buttons: "Launch / Play Video", "Copy Video Link", "Open in VLC Player", "Mark Done".
  - YouTube & HLS adaptive stream (.m3u8) support.

- 📑 **In-App PDF Notes & Resources:**
  - Quick-access sheet for lecture notes, formulas, and past papers.
  - Instant Telegram community link launcher and link copier.

- 💖 **Favorites / Bookmarks:**
  - Heart icon on any video saves it to persistent local storage.
  - Dedicated Favorites screen with quick access to all saved lectures.

- 🌗 **Adaptive Material 3 Design:**
  - Full Dark Mode and Light Mode support with smooth transition.
  - Custom Google Fonts typography (Inter).
  - Responsive layout adapting to phones, tablets, and wide desktop screens.

---

## 🚀 How to Run

### Option 1: Double-click Launcher
Simply double-click **`Run_Study_Hub.bat`** on your desktop. It provides an interactive menu:
1. Windows Desktop App (`flutter run -d windows`)
2. Google Chrome Web (`flutter run -d chrome`)
3. Pre-built Fast Local Web App (`http://localhost:5500`)
4. Build Android APK (`flutter build apk`)

### Option 2: Command Line

#### Run on Windows Desktop:
```bash
flutter run -d windows
```

#### Run on Chrome / Web:
```bash
flutter run -d chrome
```

#### Run on Connected Android Phone:
```bash
flutter run -d android
```

#### Build Release Android APK:
```bash
flutter build apk --release
```

#### Build Web Production Bundle:
```bash
flutter build web
```

---

## 📁 Project Architecture

```
lib/
├── main.dart                          # Application entry point & providers setup
├── models/
│   ├── subject.dart                   # CourseSubject model
│   ├── unit.dart                      # CourseUnit model
│   └── video_lecture.dart             # VideoLecture model
├── services/
│   ├── crypto_service.dart            # PBKDF2, HKDF & AES-GCM decryption
│   ├── storage_service.dart           # SharedPreferences local storage
│   └── media_resolver_service.dart    # Video & stream URL resolution
├── providers/
│   ├── theme_provider.dart            # Dark/Light theme mode state
│   ├── catalog_provider.dart          # Catalog decryption, index & search
│   └── study_progress_provider.dart   # Favorites & completion progress
├── screens/
│   ├── unlock_screen.dart             # Password unlock screen & demo mode
│   ├── home_screen.dart               # Subject grid, stats & search
│   ├── subject_detail_screen.dart     # Unit list & subject progress
│   ├── unit_detail_screen.dart        # Video lectures checklist & viewer
│   ├── video_player_screen.dart       # Video stream modal & VLC launcher
│   ├── pdf_notes_screen.dart          # Notes viewer & Telegram group launcher
│   └── favorites_screen.dart          # Bookmarked lectures screen
├── widgets/
│   ├── search_bar_widget.dart         # Responsive search input
│   ├── subject_card.dart              # Material 3 subject card with hue accent
│   ├── video_tile.dart                # Video row with play, favorite & done
│   └── study_stats_header.dart        # Learning overview card & badges
└── utils/
    ├── app_colors.dart                # Color tokens & subject hues
    └── app_theme.dart                 # Material 3 light/dark themes
```
