# Time Scopes

Time Scopes is a SwiftUI iOS app for visualizing life-time metrics, calendar and reminder events, and Screen Time usage in the Pulse tab.

**Features**
- Home dashboard with life-time and remaining-time metrics.
- Calendar and Reminders timeline views (read-only).
- Pulse Screen Time reports (weekly, daily, and today).
- Preferences tab for managing permissions.

**Requirements**
- iOS 18.5 deployment target (see project settings).
- Screen Time data requires a real device and user authorization.

**Build**
```bash
open "Time Scopes.xcodeproj"
```

```bash
xcodebuild -scheme "Time Scopes" build
```

**Tests (TDD)**
```bash
xcodebuild -scheme "Time Scopes" test -destination "platform=iOS Simulator,name=iPhone 17"
```

```bash
scripts/ci/run_tests_with_coverage.sh
```

- `scripts/ci/run_tests_with_coverage.sh` executes tests with code coverage and applies a minimum coverage gate.
- Coverage threshold can be overridden per run:
  - `MIN_COVERAGE=55 scripts/ci/run_tests_with_coverage.sh`
- CI runs automatically on `main` and `codex/**` pushes and on every pull request (`.github/workflows/ios-tests.yml`).

**Permissions**
- Calendar access (EventKit).
- Reminders access (EventKit).
- Screen Time access (FamilyControls + DeviceActivity).

**Project Structure**
- `Time Scopes/` SwiftUI app source.
- `Time Scopes/App/View/` screens and reusable views.
- `Time Scopes/App/Domain/` models and calculation services.
- `Time Scopes/App/Data/` persistence and store abstractions.
- `Time Scopes/App/Events/` and `Time Scopes/App/User/` time/event calculations and user state.
- `Time Scopes/App/Utility/` UI helpers and date utilities.
- `PulseReportExtension/` DeviceActivity report extension used by Pulse.
- `Resource/` design assets and screenshots (not shipped in the app bundle).
