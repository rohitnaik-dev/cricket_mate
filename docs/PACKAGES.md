# Package Dependencies & Justifications

Every third-party package introduced to CricketMate must have a one-line justification recorded in this document before or at the time it is added to `pubspec.yaml`.

---

| Package | Classification | Justification |
|---|---|---|
| `flutter_riverpod` | Direct Dependency | Compile-safe, testable state management and dependency injection without BuildContext dependency. |
| `dio` | Direct Dependency | Robust HTTP client supporting connection timeouts, response parsing, and error mapping for Open-Meteo APIs. |
| `shared_preferences` | Direct Dependency | Lightweight persistent key-value storage for offline caching, app settings, and preferred cricket venue. |
| `intl` | Direct Dependency | Internationalization, localized date, time, and timestamp formatting for cricket session intervals. |
| `flutter_localizations` | SDK Dependency | Core Flutter SDK localization support for localized widgets, calendars, and date/time pickers. |
| `flutter_lints` | Dev Dependency | Enforces official Flutter community and Dart team style and quality linting rules. |
| `mocktail` | Dev Dependency | Clean, null-safe mocking library for unit testing repositories, API clients, and Riverpod notifiers without code generation. |
| `flutter_test` | SDK Dev Dependency | Core Flutter SDK testing framework for widget and unit test verification. |
| `share_plus` | Direct Dependency | Cross-platform native system share sheet to invite cricket squad members via WhatsApp and messaging apps. |
