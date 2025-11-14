# CARRIAGE — My Truck Project

A complete full-stack mobile + web application for truck/carriage management.
This repository contains a Laravel-powered backend (`back-end/`) and a Flutter-based mobile app (`frontend/`). The project aims to provide fleet owners and drivers with tools for vehicle listing, location, media handling, and secure API access.

---

## Highlights

- Backend: Laravel 11, PHP 8.2+ with Sanctum for API authentication and Vite for asset bundling.
- Frontend: Flutter app (Flutter SDK compatible with Dart SDK ^3.5.0) with maps, camera, and media handling.
- Modular repo layout: `back-end/` (API + admin) and `frontend/` (mobile apps for Android / iOS / Web).

---

## Repository Structure

- `back-end/` — Laravel application (API, web routes, migrations, seeders, tests)
- `frontend/` — Flutter application (mobile UI, assets, platform configs)
- `assets/` — Shared assets used by the Flutter app (icons, fonts, images, video)

---

## Quick Start

1. Backend (Laravel)

   - Copy environment and install dependencies:

     ```bash
     cd back-end
     cp .env.example .env
     composer install
     npm install
     ```

   - Generate an application key, run migrations and create storage link:

     ```bash
     php artisan key:generate
     php artisan migrate
     php artisan storage:link
     npm run dev   # for Vite dev server / asset building
     php artisan serve --host=127.0.0.1 --port=8000
     ```

   - Optional: create a local SQLite DB (used by the Laravel default post-create script):

     ```bash
     touch database/database.sqlite
     php artisan migrate --seed
     ```

2. Frontend (Flutter)

   - Install Flutter SDK (recommended stable release compatible with Dart SDK ^3.5.0).
   - Fetch dependencies and run the app:

     ```bash
     cd frontend
     flutter pub get
     flutter run            # run on connected device or emulator
     flutter build apk      # build an Android release
     flutter build ios      # build for iOS (macOS required)
     ```

   - The Flutter app ships with assets listed in `frontend/pubspec.yaml` (icons, videos, images, fonts).

---

## Environment & Configuration

- Backend
  - Copy `.env.example` to `.env` and configure the DB credentials, `APP_URL`, mail, and any third-party keys.
  - If using Sanctum for SPA/mobile authentication, configure `SANCTUM_STATEFUL_DOMAINS` and CORS in `config/cors.php`.

- Frontend
  - The Flutter app uses `flutter_dotenv` for environment variables. Create a `.env` in `frontend/` if needed and load values according to your app code.
  - Ensure the app’s API base URL matches the backend (for development `http://10.0.2.2:8000` for Android emulator, or `http://127.0.0.1:8000` for iOS simulator / web).

---

## Development Notes

- Tech stack discovered from repository files:
  - `back-end/composer.json` indicates Laravel `^11.9`, PHP `^8.2`, `laravel/sanctum` for authentication, Vite integration and PHPUnit for tests.
  - `back-end/package.json` uses Vite and `laravel-vite-plugin` for frontend asset bundling.
  - `frontend/pubspec.yaml` lists Flutter packages used: `camera`, `video_player`, `image_picker`, `geolocator`, `geocoding`, `flutter_map`, `provider`, `flutter_dotenv`, and more.

- Authentication: API tokens / cookie-based auth likely via Laravel Sanctum — configure Flutter to use token-based flows or cookie-based as implemented in backend controllers.
- Media & assets: Flutter assets (images, splash video) live under `frontend/assets/` and referenced in `pubspec.yaml`.

---

## Running Tests

- Backend unit tests (PHPUnit):

  ```bash
  cd back-end
  ./vendor/bin/phpunit
  ```

- Flutter widget/unit tests (if present):

  ```bash
  cd frontend
  flutter test
  ```

---

## Common Commands

- Backend

  - Install PHP deps: `composer install`
  - Run migrations: `php artisan migrate`
  - Run dev server: `php artisan serve`
  - Seed DB: `php artisan db:seed`

- Frontend

  - Get packages: `flutter pub get`
  - Run on device: `flutter run`
  - Build Android APK: `flutter build apk`
  - Build iOS: `flutter build ios`

---

## Deployment Suggestions

- Backend: Deploy to a managed PHP host or container platform (Forge, Vapor, Docker, or traditional VPS). Use `php artisan config:cache`, `route:cache`, and `queue:work` in production. Serve assets built with `npm run build` or integrate into CI.
- Frontend: Publish Flutter builds to Google Play / App Store. For web, `flutter build web` and host on static hosting.

---

## Contribution

Contributions, issues, and feature requests are welcome. Please follow these steps:

1. Fork the repository.
2. Create a feature branch (`git checkout -b feat/your-feature`).
3. Commit your changes (`git commit -m 'Add feature'`).
4. Push to the branch (`git push origin feat/your-feature`).
5. Open a Pull Request describing your changes.

Please include tests where possible and run existing tests before submitting.

---

## License

This project uses code from Laravel which is licensed under the MIT license. Unless otherwise specified, the project files in this repository are provided under the MIT license.

---

If you want, I can also:

- Add CI (GitHub Actions) workflow to run backend tests and Flutter tests.
- Add badges (build / tests / license) to the README header.
- Extract more detailed API docs (endpoints, auth flows) by scanning controllers and route files.

Tell me which of the above you'd like me to do next.
# befor php artsian serve do this things 
    -- cp .env.example .env
    -- php artisan key:generate
    -- php artisan storage:link
    --php artisan migrate
    -- php artisan serve