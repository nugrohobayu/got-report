# myapp

Boilerplate Flutter production-ready dengan clean architecture (feature-first), `flutter_bloc` untuk state management, dan DI berbasis `RepositoryProvider`/`BlocProvider` (tanpa `get_it`/service locator).

## Requirements

- [FVM](https://fvm.app/) sudah terpasang
- Flutter **3.27.3** (dikelola lewat FVM — lihat `.fvmrc`)

Project ini **wajib** dijalankan lewat FVM. Semua perintah `flutter`/`dart` harus di-prefix `fvm`.

## Setup

```bash
# 1. Pastikan FVM memakai versi Flutter yang benar (sudah di-pin di .fvmrc)
fvm use 3.27.3

# 2. Salin konfigurasi environment
cp .env.example .env
# lalu sesuaikan BASE_URL bila perlu

# 3. Install dependencies
fvm flutter pub get
```

## Menjalankan aplikasi

```bash
fvm flutter run
```

## Verifikasi

```bash
fvm flutter analyze
fvm flutter test
```

## Struktur folder

Feature-first / clean architecture, dipisah menjadi 3 layer per fitur (`data`, `domain`, `presentation`):

```
lib/
├── core/
│   ├── constants/    # AppConstants, ApiEndpoints (base URL dari .env)
│   ├── network/      # ApiClient (wrapper package:http) reusable di semua fitur
│   ├── error/        # Exception (data layer) & Failure (domain/presentation layer)
│   ├── theme/        # AppTheme (light/dark) + ThemeCubit (persist via shared_preferences)
│   ├── router/        # AppRouter (go_router)
│   ├── utils/        # DateFormatter, preference keys, dll
│   └── widgets/       # Widget generik yang dipakai lintas fitur (mis. ErrorView)
├── features/
│   └── posts/
│       ├── data/
│       │   ├── models/          # PostModel (fromJson/toJson)
│       │   ├── datasources/     # PostsRemoteDataSource (panggil ApiClient)
│       │   └── repositories/    # PostsRepositoryImpl (map Exception -> Failure)
│       ├── domain/
│       │   ├── entities/        # Post (pure Dart, tanpa dependency Flutter)
│       │   ├── repositories/    # PostsRepository (abstract)
│       │   └── usecases/        # GetPosts
│       └── presentation/
│           ├── bloc/            # PostsBloc, PostsEvent, PostsState
│           ├── pages/           # PostsPage (list), PostDetailPage
│           └── widgets/         # PostListItem
└── main.dart
```

### Alur dependency

```
presentation → domain ← data
```

`domain` tidak bergantung pada `data` maupun `presentation` (dependency inversion): `data` mengimplementasikan interface (`PostsRepository`) yang didefinisikan di `domain`, dan `presentation` hanya bergantung pada `domain` (entities, usecases, repository abstract).

## Dependency Injection

**Tidak memakai `get_it`.** DI dilakukan murni dengan widget bawaan `flutter_bloc`/`provider`:

- `MultiRepositoryProvider` di `main.dart` menyediakan `ApiClient` → `PostsRemoteDataSource` → `PostsRepository` ke seluruh widget tree, masing-masing di-*inject* lewat `context.read<...>()` pada `create` provider di atasnya.
- `BlocProvider` menyediakan `PostsBloc` pada level halaman (`PostsPage`), mengambil `GetPosts` usecase yang dibangun dari `PostsRepository` lewat `context.read<PostsRepository>()`.
- `ThemeCubit` (persist tema lewat `shared_preferences`) disediakan sebagai `BlocProvider` di root, menerima `SharedPreferences` lewat constructor yang sudah di-`await` di `main()`.

## State management

`flutter_bloc` dengan pemisahan event/state/bloc yang rapi. Fitur `posts` mendemonstrasikan alur lengkap **loading → success → error**:

1. `PostsPage` membuat `PostsBloc` dan langsung men-dispatch `PostsRequested`.
2. `PostsBloc` emit `PostsStatus.loading`, memanggil `GetPosts` usecase.
3. Berhasil → emit `PostsStatus.success` berisi daftar `Post`.
4. Gagal (network/timeout/status non-2xx/parsing) → `PostsRepositoryImpl` melempar `Failure` yang sesuai, ditangkap `PostsBloc`, emit `PostsStatus.error` dengan pesan yang bisa ditampilkan ke user beserta tombol **Retry**.

## Networking

- `package:http` (bukan `dio`), dibungkus `ApiClient` (`lib/core/network/api_client.dart`) yang reusable untuk semua fitur.
- Base URL terpusat lewat `AppConstants.baseUrl`, dibaca dari `.env` (`flutter_dotenv`).
- Error handling lengkap: `NetworkException` (tidak ada koneksi), `ApiTimeoutException` (timeout), `ServerException` (status non-2xx), `ParsingException` (body tidak bisa di-decode).
- Contoh end-to-end: `GET https://jsonplaceholder.typicode.com/posts` lewat fitur `posts`.

## Routing

`go_router` dengan dua route dasar:

- `/` — `PostsPage` (daftar post)
- `/posts/:id` — `PostDetailPage` (detail post, data dikirim lewat `extra`)

## Theming

`AppTheme.light` / `AppTheme.dark` (Material 3, `ColorScheme.fromSeed`). Toggle tema dari ikon di `AppBar` pada `PostsPage`, tersimpan otomatis lewat `ThemeCubit` + `shared_preferences`.

## Environment variables

Salin `.env.example` menjadi `.env` sebelum menjalankan aplikasi:

```
BASE_URL=https://jsonplaceholder.typicode.com
```

`.env` di-*gitignore*-kan agar konfigurasi lokal/rahasia tidak ter-commit; `.env.example` menjadi acuan untuk developer lain.

## Target platform

- Android `minSdk` 21
- iOS deployment target 12.0
- Null-safety aktif (Dart SDK `^3.6.1`, sesuai Flutter 3.27.3)
