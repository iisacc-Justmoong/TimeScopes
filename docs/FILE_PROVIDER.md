# File creation ownership in TimeScopes

Journal lock creation and widget snapshot persistence use the native Swift provider. The Xcode application/widget/test source groups compile the same SDK source.

The common [ownership contract](../../../../SDK/iiFileProvider/docs/FILE_OWNERSHIP.md) defines stream, staging, control-file and
installed-package rules. Source regression tests remain with this module; the
workspace creation audit also checks these boundaries. Build/deployment and target
runtime validation are separate evidence.

Changed boundaries:


- `src/Time Scopes/App/Shared/PulseJournalStorageCoordinator.swift`
- `src/Time Scopes/App/Shared/WidgetSnapshotStore.swift`
