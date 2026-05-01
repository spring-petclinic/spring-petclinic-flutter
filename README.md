# Spring Petclinic Flutter

[![Flutter CI](https://github.com/spring-petclinic/spring-petclinic-flutter/actions/workflows/dart.yml/badge.svg?branch=master)](https://github.com/spring-petclinic/spring-petclinic-flutter/actions/workflows/dart.yml)
[![OSV Scanner](https://github.com/spring-petclinic/spring-petclinic-flutter/actions/workflows/osv-scanner.yml/badge.svg?branch=master)](https://github.com/spring-petclinic/spring-petclinic-flutter/actions/workflows/osv-scanner.yml)
[![Semgrep](https://github.com/spring-petclinic/spring-petclinic-flutter/actions/workflows/semgrep.yml/badge.svg?branch=master)](https://github.com/spring-petclinic/spring-petclinic-flutter/actions/workflows/semgrep.yml)
[![CodeQL](https://github.com/spring-petclinic/spring-petclinic-flutter/actions/workflows/codeql.yml/badge.svg?branch=master)](https://github.com/spring-petclinic/spring-petclinic-flutter/actions/workflows/codeql.yml)

Flutter frontend for [Spring Petclinic](https://github.com/spring-petclinic). This app targets Android and web, mirrors
the functional flows of the [Angular frontend](https://github.com/spring-petclinic/spring-petclinic-angular), and uses the same REST backend exposed by 
[spring-petclinic-rest](https://github.com/spring-petclinic/spring-petclinic-rest).

The CI status includes static analysis, tests, the web build, and the Android debug APK build.

## Screenshots

### Web

<p align="center">
  <img src="docs/screenshots/web-owners.png" width="900" alt="Spring Petclinic owners screen on web" />
  <img src="docs/screenshots/web-owners-details.png" width="900" alt="Spring Petclinic owners details screen on web" />
</p>

### Android

<p align="center">
  <img src="docs/screenshots/mobile-home.jpeg" width="260" alt="Spring Petclinic home screen on Android" />
  <img src="docs/screenshots/mobile-owner-details.jpeg" width="260" alt="Spring Petclinic owner details screen on Android" />
</p>

## Backend

Start the backend first:

```bash
cd ~/spring-petclinic-rest
./mvnw spring-boot:run
```

The expected API is:

```text
http://localhost:9966/petclinic/api
```

## API configuration

The app resolves the API base URL in this order:

1. `PETCLINIC_API_BASE_URL` passed with `--dart-define`
2. Platform default

Platform defaults:

- Android emulator: `http://10.0.2.2:9966/petclinic/api`
- Web: `http://localhost:9966/petclinic/api`
- Other non-Android platforms: `http://localhost:9966/petclinic/api`

That logic lives in:

```text
lib/shared/config/api_config.dart
```

Override it at runtime when needed:

```bash
flutter run --dart-define=PETCLINIC_API_BASE_URL=http://<host>:9966/petclinic/api
```

Use an explicit override when:

- running on a physical Android device;
- serving the web app against a backend that is not on `localhost`;
- pointing the app to a shared/staging backend.

## Run on Android

For an Android emulator:

```bash
cd ~/spring-petclinic-flutter
flutter pub get
flutter run
```

For a physical Android device, pass the host machine IP explicitly:

```bash
flutter run --dart-define=PETCLINIC_API_BASE_URL=http://<host>:9966/petclinic/api
```

## Run on Web

For local browser development against the backend running on the same machine:

```bash
cd ~/spring-petclinic-flutter
flutter pub get
flutter run -d chrome
```

If the backend is not reachable at `http://localhost:9966/petclinic/api`, pass an override:

```bash
flutter run -d chrome --dart-define=PETCLINIC_API_BASE_URL=http://<host>:9966/petclinic/api
```

## Build

Build an Android debug APK:

```bash
flutter build apk --debug
```

Build the web app:

```bash
flutter build web
```

## Validation

Typical checks:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter build web
```

GitHub Actions also runs dependency vulnerability scanning with OSV Scanner,
an advisory Semgrep scan, and CodeQL analysis for workflow security.

## Contributing

The [issue tracker](https://github.com/San-43/spring-petclinic-flutter/issues) is the preferred channel for bug reports, feature requests, and submitting pull requests.

For pull requests, please keep the existing Flutter and Dart code style and make sure the validation commands listed above pass before submitting changes.
