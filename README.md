# FOMI Mobile App

Flutter mobile app untuk user panel FOMI dengan cakupan fitur auth, dashboard, QR code management, orders, profile, renewal payment via Midtrans Snap, dan merchandise.

## Arsitektur Singkat

- UI: Flutter Material 3 screens per fitur pada folder lib/screens.
- State management: Provider, fokus pada AuthProvider untuk auth guard.
- Routing: GoRouter dengan route protection berbasis status login.
- Networking: Dio + interceptor bearer token.
- Service layer: Satu service per domain API agar mudah dites dan dipelihara.
- Data contract: Model Dart di lib/models dan kontrak TypeScript di api-types.ts.

## Struktur Folder Utama

- lib/core: API client dan interceptor
- lib/models: model response dan pagination
- lib/providers: auth provider
- lib/services: service API per fitur
- lib/screens: seluruh screen dan alur navigasi
- test/services: unit test service
- api-types.ts: TypeScript types untuk response utama API

## Endpoint Yang Sudah Dipakai

- POST /api/login
- POST /api/register
- POST /api/logout
- GET /api/me
- GET /api/user/dashboard
- GET /api/user/qrcodes
- PUT /api/user/qrcodes/{asset}
- PATCH /api/user/qrcodes/{asset}/toggle-lost
- GET /api/user/orders
- GET /api/user/orders/{order}
- GET /api/user/profile
- PUT /api/user/profile
- PUT /api/user/profile/password
- PUT /api/user/profile/privacy
- GET /api/user/renewal/packages
- POST /api/user/renewal/checkout
- POST /api/midtrans/check-status
- POST /api/merchandise/scan/verify
- POST /api/merchandise/activate
- GET /api/merchandise/my-items

## Setup Environment

1. Install Flutter SDK stable.
2. Jalankan flutter doctor dan pastikan Android toolchain siap.
3. Install dependency:

	flutter pub get

4. Set base URL API lewat dart-define saat run:

	flutter run --dart-define=API_BASE_URL=https://your-domain/api

Jika dart-define tidak diberikan, default base URL adalah https://fomi.syahrulcaem.my.id/api.

## Cara Menjalankan

1. Pastikan emulator Android aktif atau device terhubung.
2. Jalankan:

	flutter run --dart-define=API_BASE_URL=https://your-domain/api

## Build APK Debug

Jalankan command berikut:

flutter build apk --debug --dart-define=API_BASE_URL=https://your-domain/api

Output APK debug ada di:

build/app/outputs/flutter-apk/app-debug.apk

## Menjalankan Unit Test

flutter test
