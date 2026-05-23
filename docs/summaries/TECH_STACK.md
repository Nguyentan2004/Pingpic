# 🛠 PingPic - Technology Stack

This document details the core framework, libraries, and utilities that power the PingPic real-time photo-sharing ecosystem.

---

## 🏗 Framework & Core Runtime

- **Language**: **Dart 3.x**
  - Robust static typing, extension methods, and asynchronous streams.
  - Native compilations for Android and high-performance JS/CanvasKit rendering for Web.
- **Framework**: **Flutter Web & Mobile (Material 3)**
  - Unified declarative UI engine with custom multi-platform rendering pipelines.
  - Supports desktop-grade layouts, tablet interfaces, and native mobile shells.

---

## ⚡ State Management & Navigation

- **State Container**: **Provider (`^6.1.2`)**
  - High-performance, low-boilerplate dependency injection and state tracking.
  - Distinct modular providers to ensure clean separation of concerns:
    - `AuthProvider`: Manages user credentials, JWT secure tokens, and firebase auth states.
    - `FeedProvider`: Manages reactive feed streams, double-tap liking events, and comments.
    - `HistoryProvider`: Manages grid/list moment history listings and deletion operations.
    - `FriendProvider`: Manages active friend lists, search results, and pending requests.
    - `ThemeProvider`: Manages dynamic Light/Dark mode state preferences.
    - `EditorProvider`: Manages drag-and-drop overlay sticker layers and freehand sketch drawing data.
- **Routing Engine**: **GoRouter (`^14.3.0`)**
  - Native browser URL sync, backing/forward navigation, deep-linking, and dynamic path parameters (e.g. `/profile/:userId`).
  - Seamless route guards checking authentication status on launch.

---

## ☁ Backend & Real-time Services (Firebase)

- **Firebase Core (`^3.11.0`)**: Central engine binding standard Google Cloud services to Flutter.
- **Firebase Auth (`^5.5.1`)**: Session persistence, login validation, and secure authentication tokens.
- **Cloud Firestore (`^5.6.3`)**: Real-time NoSQL cloud database feeding immediate snapshot streams.
- **Firebase Storage (`^12.4.1`)**: Optimized high-capacity binary storage for uploaded photos (moments).
- **Firebase Messaging (`^15.2.10`)**: Background cloud dispatching for native push notifications.

---

## 📸 Media Handling & Canvas Compositing

- **Web Camera Picker (`image_picker` + `image_picker_for_web`)**: Captures webcam screenshots or local media explorer selections with fallback prompts.
- **Overlay Editors**:
  - `emoji_picker_flutter`: Category-based emoji stickers.
  - `giphy_get`: Dynamic moving GIF selections utilizing GIPHY APIs.
- **Compositing Engine**:
  - Utilizes custom Flutter canvas drawings to rasterize overlays, vector strokes, and text layers onto source image byte lists prior to uploading to Storage, ensuring single-file consistency.

---

## 🔒 Storage & Caching

- **SharedPreferences (`^2.5.5`)**: Stores light metadata including chosen theme modes, selected languages, and persistent session preferences (`remember_me`).
- **Flutter Secure Storage (`^9.2.2`)**: Encrypted storage utilizing keychain/keystore APIs to protect session keys and tokens on mobile devices.
- **CachedNetworkImage (`^3.4.1`)**: Caches network images locally, reducing API requests and network overhead.

---

## 🎨 UI/UX & Micro-interactions

- **Skeleton Shimmer (`shimmer ^3.0.0`)**: Renders smooth grey loading placeholders for feeds and grid histories during network fetches.
- **Lottie (`lottie ^3.1.3`)**: Plays lightweight vector animations (e.g. dynamic hearts on double-tap).
- **Google Fonts (`google_fonts ^6.2.1`)**: CDN-based high-quality typography rendering (Inter/Outfit).
- **Cupertino Icons (`^1.0.8`)**: Fallback high-fidelity iOS interface icon kits.
