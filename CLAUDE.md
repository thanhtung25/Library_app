# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter mobile app — Library Management System with authentication, book catalog, borrowing/returning, favorites, and reservations. UI strings are currently hardcoded in Russian.

- **Dart SDK:** ^3.9.2
- **State management:** flutter_bloc (BLoC pattern)
- **Networking:** `http` package with custom `ApiService` wrapper (static methods)
- **Backend:** Flask/Python API server on port 5000

## Common Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator (Android)
flutter run -d chrome    # Run on web (uses different base URL)
flutter analyze          # Static analysis
flutter test             # Run tests
```

## Architecture

```
lib/
├── main.dart                    # Entry point → MyApp
├── myApp.dart                   # MultiBlocProvider + MaterialApp (onGenerateRoute)
├── Router/
│   ├── AppRoutes.dart           # Route name constants
│   └── AppRouter.dart           # Route generation with typed arguments
├── api_localhost/
│   ├── ApiService.dart          # Base HTTP client (static get/post/put/delete)
│   └── {Feature}Service.dart    # Per-domain services (Auth, Book, Loan, etc.)
├── bloc/{feature}/              # One folder per feature: bloc.dart, event.dart, state.dart
├── model/                       # Data models with fromJson/toJson/copyWith
└── page/                        # UI screens grouped by feature
    ├── Login_Register_Page/     # Login, Register, PersonInfo
    ├── Home/                    # Tabbed: HomeTab, Books, Borrow, Favorite, Profile
    └── CartReservation/         # Reservation cart with delivery/payment
```

## Key Patterns

**API base URL:** `http://10.0.2.2:5000` (Android emulator) or `http://127.0.0.1:5000` (web) — hardcoded in `ApiService.dart`. Switch manually when targeting web.

**BLoC registration:** Global BLoCs in `myApp.dart` via `MultiBlocProvider`: Auth, Book, Category, Reservation, Favorite, BookCopy. Route-scoped BLoCs are created inside `AppRouter.generateRoute()` (e.g., BookBloc for BookDetailScreen).

**Routing:** `UserModel` is the primary object passed through routes. Most routes receive it via `settings.arguments`. `BookDetailScreen` receives a `Map<String, dynamic>` with both `book` and `user` keys.

**Models:** All use `factory fromJson(Map<String, dynamic>)`. JSON keys use `snake_case` (matching backend), Dart fields are mixed (`snake_case` and `camelCase`). `LoginResponse` wraps `UserModel` with success/message/token fields.

**Naming quirk:** `BookService` class is lowercase `bookService` — instantiated as `bookService()` throughout the codebase.

## Adding a New Feature

1. Create model in `lib/model/`
2. Create API service in `lib/api_localhost/`
3. Create BLoC folder in `lib/bloc/{feature}/` with `bloc.dart`, `event.dart`, `state.dart`
4. Create screen in `lib/page/{Feature}/`
5. Add route constant in `AppRoutes.dart` and case in `AppRouter.generateRoute()`
6. Register BLoC in `myApp.dart` (global) or in the route (screen-specific)
