# CricketMate Workspace Rules & Guidelines

CricketMate is a production-quality Flutter take-home application designed as a cricket session planner: *"When should our group play cricket today?"*. It combines Open-Meteo weather data with player availability to recommend and schedule optimal playing sessions.

---

## Standing Architectural & Development Rules

### 1. Flutter & Dart Standards
- **Version & Language Features**: Use the latest stable Flutter and Dart releases. Leverage modern Dart 3 features throughout the codebase:
  - **Sealed classes / class hierarchies** for exhaustive state modeling and domain results.
  - **Records & Destructuring** for lightweight grouping of return values.
  - **Pattern matching & switch expressions** for clean, exhaustive handling of states and UI rendering.
- **Analysis & Formatting**:
  - Maintain `flutter_lints` with **zero analyzer warnings or errors** at all times.
  - Keep code cleanly formatted with standard `dart format`.

### 2. Project Structure & Architecture
- **Feature-First Architecture**: Group code by feature first (e.g., `features/weather`, `features/session_planner`, `features/availability`), not layer-first.
- **Strict Layer Separation**:
  - `data/`: API clients, data sources, and raw models/DTOs.
  - `repository/`: Abstract and concrete repositories mediating between data sources, caching, and domain logic.
  - `state/`: Riverpod providers, Notifiers, and state management.
  - `ui/`: Screens, widgets, and presentation logic.
- **Separation of Concerns**: **Widgets NEVER call HTTP directly.** All network calls must pass through data sources -> repositories -> Riverpod state providers -> UI.

### 3. Data Models & Test Data Integrity
- **Models**: Hand-written, typed, immutable data classes with robust `fromJson` deserialization (and `toJson` where needed).
- **No Mock or Seeded Data in `lib/`**: `lib/` must contain only production code. All mock data, test fixtures, and sample payloads belong strictly under `test/` (e.g., `test/fixtures/`).

### 4. Dependency Management
- **Justification Required**: Every added third-party package must be documented and justified in a single line in [`docs/PACKAGES.md`](file:///c:/Users/rohit/Desktop/majhe-test/cricket_mate/docs/PACKAGES.md).
- Keep dependencies minimal, well-maintained, and production-ready.

### 5. Git & Security
- **No Secrets**: Never commit API keys, tokens, or sensitive credentials into the repository.
- **Small Commits**: Commit frequently with focused, single-concern commits following standard conventional commit messages (e.g., `feat:`, `fix:`, `docs:`, `refactor:`, `test:`).

### 6. UI & Responsive Design Constraints
- **Widget Composition**: Build small, reusable `const` widgets to optimize rebuilds and rendering performance.
- **Accessibility & Scaling**: Ensure the UI scales cleanly with system text scaling up to **200%** without text clipping or layout breaks.
- **Responsiveness**:
  - Zero layout overflows (`RenderFlex` errors) across all device sizes, down to narrow **320dp width** screens.
  - Support portrait and landscape orientations gracefully using scroll views, layout builders, and responsive padding.
