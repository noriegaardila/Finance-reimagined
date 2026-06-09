# Finance Reimagined — AI Workspace Context

## Project
Flutter iOS personal finance app. Parses bank SMS messages and logs transactions locally. No backend.

## Branch
Active development branch: `claude/workspace-unification-logs-75eo17`
Draft PR: #1 (from `claude/bank-sms-extraction-aQWqC` → `main`)

## Architecture
- `lib/services/sms_parser.dart` — regex engine covering 13 banks
- `lib/services/deep_link_service.dart` — iOS Shortcuts via `fintrack://add-sms?text=…`
- `lib/screens/` — home dashboard, transaction list, detail, SMS entry
- `lib/providers/transaction_provider.dart` — Provider state management
- `lib/services/storage_service.dart` — local JSON persistence
- `ios/Runner/Info.plist` — registers `fintrack` URL scheme
- `docs/ios-shortcuts-setup.md` — Shortcuts automation guide

## Key Commands
```bash
flutter pub get        # install dependencies
flutter test           # run unit tests
flutter run            # run on iOS simulator
```

## AI Tools Config
All tools configured for this workspace. Shared credential helper: `git credential.helper=store`.
GitHub identity: set via `~/.gitconfig` (user.name / user.email).
