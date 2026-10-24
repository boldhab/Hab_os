# HabOS Mobile & Web Client

> **Cross-platform client application for HabOS (Personal Life Operating System), built with Flutter Clean Architecture and Riverpod state management.**

---

## 📱 Overview

The HabOS client provides a responsive, offline-capable interface for managing all 24 life domains—ranging from daily task lists and focus timers to GitHub synchronization, gym tracking, and real-time Life Score analytics.

---

## 🏗️ Architecture

The client strictly adheres to **Flutter Clean Architecture** decoupled into 4 layers:

```
client/lib/
├── app/                  # Application bootstrap, routing (GoRouter), theme configuration
├── core/                 # Shared networking (Dio), interceptors, constants, errors
├── domain/               # Enterprise business models (pure Dart, zero UI dependency)
├── data/                 # DTOs, JSON serialization, REST data sources, repository implementations
├── infrastructure/       # Platform-level device services (local notifications, secure hardware keystore)
└── presentation/         # Riverpod providers, UI widgets, screens, and dialogs
```

---

## ⚙️ Getting Started

### Prerequisites

* **Flutter SDK**: `v3.19.x` or newer (`flutter --version`)
* **Dart SDK**: `^3.0.0`
* **Android Studio / Xcode**: For mobile emulator or device compilation

### Installation

1. Navigate to the client directory:
   ```bash
   cd client
   ```

2. Fetch dependencies:
   ```bash
   flutter pub get
   ```

3. Run Flutter Doctor to ensure environment readiness:
   ```bash
   flutter doctor
   ```

---

## 🌐 Backend API Configuration

The client dynamically resolves the backend URL via `--dart-define`.

* **Local Machine / Desktop / Web**: Defaults to `http://localhost:5000/api/v1`
* **Android Emulator**: Automatically defaults to `http://10.0.2.2:5000/api/v1`
* **Physical Device or Remote Server**: Supply your machine's local IP or remote domain at run/build time:

```bash
# Running on physical device (replace with your machine's LAN IP):
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:5000/api/v1

# Running with Production Backend:
flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
```

---

## 🚀 Running & Building

### Development Mode

```bash
# Run on default connected device / emulator:
flutter run

# Run on Chrome (Web):
flutter run -d chrome
```

### Production Release Builds

```bash
# Build Android APK (Release):
flutter build apk --release --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1

# Build Android App Bundle (Play Store):
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1

# Build Web (SPA):
flutter build web --release --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
```

---

## 🧪 Testing

Run automated unit and widget tests:

```bash
flutter test
```
