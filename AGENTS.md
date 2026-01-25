# Repository Guidelines

## Project Structure & Module Organization
- `Time Scopes/` holds the SwiftUI app source.
  - `App/View/` contains SwiftUI screens and reusable views.
  - `App/Domain/` contains models and calculation services.
  - `App/Data/` contains persistence and store abstractions.
  - `App/Events/` and `App/User/` group time/event calculations and user state.
  - `App/Utility/` holds UI helpers and date utilities.
- `Time Scopes.xcodeproj/` is the Xcode project and scheme configuration.
- `Resource/` stores design assets and screenshots (do not ship in the app bundle).

## Build, Test, and Development Commands
- `open "Time Scopes.xcodeproj"` — open the project in Xcode.
- `xcodebuild -scheme "Time Scopes" build` — build the app from the CLI.
- `xcodebuild -scheme "Time Scopes" test -destination "platform=iOS Simulator,name=<Device>"` — run tests (add a simulator name). Note: no test target is currently defined.

## Coding Style & Naming Conventions
- Swift + SwiftUI throughout the app; stick to Swift 4‑space indentation as in existing files.
- Types and views use `PascalCase` (e.g., `UserProfile`, `HomeView`).
- Properties, functions, and locals use `camelCase` (e.g., `userData`, `remainingTime`).
- Keep view files focused and prefer small subviews in `App/View/` when a screen grows.

## Testing Guidelines
- There is no XCTest target in the repository yet. If adding tests, create an Xcode test target and place files alongside the app using `*Tests.swift` naming.
- Prefer testing domain services in `App/Domain/Services/` since they are logic-heavy and UI-independent.

## Commit & Pull Request Guidelines
- Recent commits use short, imperative subject lines (e.g., “Refactor time calculations into domain layer”). Keep them concise and action‑oriented.
- PRs should describe user‑visible changes, list any new calculations or model changes, and include UI screenshots for view updates.
- Call out data‑model changes in `UserDefaults` stores to avoid migration surprises.
