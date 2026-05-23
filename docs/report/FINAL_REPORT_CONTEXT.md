# 📄 PingPic - Technical Final Report & AI Context

This unified context document compiles all technical milestones, optimizations, and architectural designs inside the PingPic repository. It serves as an authoritative reference for final report writing, system audits, and onboarding future AI agents.

---

## 📌 Executive Project Summary

PingPic is a real-time, cross-platform photo-sharing platform designed with the user experience of dynamic status-sharing applications (similar to Locket) but optimized for high-performance Web environments. Built upon Flutter (using the Material 3 design system) and powered by Firebase, the system bridges the gap between responsive web applications and native mobile hardware.

---

## 🏗 Architectural Blueprint

The codebase is built on **Clean Architecture** patterns combined with feature-based segmentation, guaranteeing clean boundaries and platform-independent configurations.

- **Presentation Layer**: Built on the **Provider** state container and **GoRouter** engine. It reactively handles screen configurations based on three responsive layout grids (Desktop, Tablet, Mobile) and manages routes via guard mechanisms (Splash, Auth check, and Token audit).
- **Domain Layer**: Houses pure business objects and abstract repo interfaces, shielding logic from third-party libraries.
- **Data Layer**: Implements core repositories (e.g. `PhotoRepository` and `FriendsRepository`) directly connected to **Firestore** and **Firebase Storage** APIs, parsing raw data schemas via serializable model structures (e.g., `CommentModel` and `UserModel`).
- **Core Infrastructure Layer**: Manages localized settings, theme parameters, color constants, and dynamic conditional service imports (stubs, web, and mobile adapters) to ensure safe, cross-platform compilation.

---

## ⚡ Core Real-time Integration Schemas

PingPic's real-time engine operates over a serverless architecture driven by reactive streams:

- **Firestore Mappings**: Users are indexed in `users`, and photos are documented in `moments` with array indices trackings likes. Interpersonal relations are logged under `friendships` (accepted/pending states). Comment streams exist in sub-collections under each moment ID.
- **Dynamic Chronology Sync**: Feed providers subscribe dynamically to individual friend collections, compiling, mapping, caching, sorting, and pushing updates to the UI in real-time. This dynamic mapping bypasses Firestore's standard `whereIn` array limitations.
- **Presence Services**: Establishes global listener bindings that toggle the `isOnline` boolean inside the user's Firestore document dynamically on connection status changes.

---

## 🚀 Critical Optimizations & Technical Solutions

Three critical technical problems were addressed to secure high-performance web experiences and reliable multi-platform builds:

### 1. Buttery-Smooth Snap-Scrolling (120 FPS Feed)
- **Problem**: Discrete wheel ticks throw highly fragmented pointer events in desktop web rendering engines, causing stutters and jumpy transitions in standard `PageView` feeds.
- **Solution**: Overrode web and desktop feed scroll physics with `NeverScrollableScrollPhysics` and wrapped the layout with customized event listeners. Discrete wheel rotation velocities are processed in a debouncer and animated programmatically via target page animations with cubic easing transitions, achieving 120 FPS.

### 2. Capturing-Phase Native Drag-and-Drop Image Uploader
- **Problem**: Dragging images from local file systems into browser workspaces causes modern browser engines to navigate away from the application tab to render the raw image.
- **Solution**: Implemented low-level capturing-phase event listeners (`dragover`, `drop` with `useCapture = true`) directly on the global browser window. This bypasses browser defaults and redirects the dropped file payload straight to a `FileReader`. The file is converted to a `Uint8List` byte stream and injected into the Flutter image composer pipeline.

### 3. Dynamic APK Renaming via Reflection
- **Problem**: In Gradle builds using Android Gradle Plugin 8.x and Kotlin DSL templates, editing build outputs directly leads to compiler crashes due to strict class castings and private setter methods.
- **Solution**: Created a reflection-based Kotlin setter script in `build.gradle.kts` that dynamically resolves output class setters at compile time (`getMethod("setOutputFile", File::class.java)`), invoking the rename dynamically. This ensures crash-free build releases across different AGP environments.

---

## 📊 Repository Cleanliness & Maintenance Guidance

To preserve documentation integrity, clean up root-level cluttered markdown files after migrating the content to the centralized `docs/` hub:
- All core features are documented under `docs/summaries/FEATURES_SUMMARY.md`.
- Libraries and dependencies are cataloged in `docs/summaries/TECH_STACK.md`.
- Database layouts are detailed in `docs/summaries/FIREBASE_ARCHITECTURE.md`.
- Advanced scroll overrides, drag-and-drop systems, and build fixes are documented in `docs/summaries/SYSTEM_ANALYSIS.md`.
- Chronological development roadmaps and future plans are tracked in `docs/summaries/PROJECT_PROGRESS.md`.
