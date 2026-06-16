# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flutter app (iOS-first) that builds a personal finance tracker. Since iOS does not allow apps to read SMS directly, the core workflow is: a bank SMS is forwarded into the app (via iOS Shortcuts deep link, or pasted manually), a regex-based parser extracts the transaction (amount, merchant, date, account, bank), the user reviews/edits the parsed result, and it's saved to local storage.

There is no backend — everything is local to the device/browser.

## Commands

This repo does not ship the Flutter SDK or platform scaffolding (`ios/Runner.xcodeproj`, `android/`, etc. are not committed in full) — run `./setup.sh` once after cloning on a Mac to scaffold them via `flutter create` and restore the custom `Info.plist` (which registers the `fintrack://` URL scheme).

```bash
flutter pub get                  # install dependencies
flutter test                     # run all tests
flutter test test/widget_test.dart --plain-name "parses Chase debit SMS"  # run a single test
flutter analyze                  # lint (uses analysis_options.yaml + flutter_lints)
flutter run                      # run on a connected device/simulator
flutter build web --release --base-href /Finance-reimagined/   # build the web version
```

Tests currently only cover `SmsParser` (`test/widget_test.dart`) — there are no widget/integration tests yet. When adding a new bank pattern or parsing rule, add a case there.

## Architecture

### SMS-in, transaction-out pipeline

The whole app revolves around one pipeline:

```
raw SMS text → SmsParser.parse() → ParsedSms → (user reviews in AddSmsScreen) → Transaction → TransactionProvider → StorageService
```

- **`lib/services/sms_parser.dart`** — pure, stateless regex engine. `SmsParser.parse(String)` returns `ParsedSms?` (null if the text doesn't look like a bank transaction, e.g. OTP codes or non-financial messages). It extracts amount, debit/credit type, merchant, date, account last-4, and bank name independently via separate regexes, then calls `CategoryHelper.infer()` on the merchant to guess a spending category. Bank detection (`_bankPatterns`) and category rules (`lib/utils/category_helper.dart`) are both keyword/regex lookup tables — extending support for a new bank or category is just adding an entry, not new logic.
- **`lib/screens/add_sms_screen.dart`** — the entry point for both manual paste and deep-link prefill. Parsed fields are editable before saving (the parser is best-effort, not authoritative).
- **`lib/providers/transaction_provider.dart`** — single `ChangeNotifier` holding the in-memory transaction list; derives all dashboard stats (monthly totals, category breakdown) on read rather than maintaining separate aggregate state. Call `load()` once at app start (done in `main.dart`) before relying on data being populated.
- **`lib/services/storage_service.dart`** — persists the full transaction list as one JSON blob in `shared_preferences` (chosen over `path_provider`/file storage specifically so the same code works on Flutter Web, since `path_provider` has no web filesystem). There's no incremental persistence — every add/update/delete rewrites the entire list.

### iOS Shortcuts integration (no manual paste required)

Because apps can't read SMS on iOS, automation happens via a custom URL scheme instead:

- iOS Shortcuts automation opens `fintrack://add-sms?text=<url-encoded SMS body>` when a message arrives from a bank.
- **`lib/services/deep_link_service.dart`** listens for this via the `app_links` package and pushes `AddSmsScreen(prefillText: ...)`, which auto-triggers parsing on load.
- The scheme is registered in `ios/Runner/Info.plist` under `CFBundleURLTypes` — `setup.sh` re-applies this file after `flutter create` because the generated default would overwrite it.
- Full end-user setup steps (Automation vs. Share Sheet) live in `docs/ios-shortcuts-setup.md`.

### Web build and deployment

The app also builds for web (using the HTML renderer, not CanvasKit, for SEO/text-rendering reasons — see `flutter build` command above) and is deployed to GitHub Pages:

- `.github/workflows/deploy-web.yml` builds and deploys to Pages on every push to `main`.
- The `gh-pages` branch holds the built static output directly (orphan branch, not a working source tree) for cases where it needs to be pushed manually outside the Actions workflow.
- `path_provider` is intentionally avoided (see storage section above) so the same `lib/` source works unmodified on web.
- Since this is a private personal-finance tool, `web/index.html` and `web/robots.txt` deliberately set `noindex, nofollow` — don't remove that if touching SEO/meta tags.

### Theming

`lib/theme/app_theme.dart` defines color constants (`kPrimary`, `kDebit`, `kCredit`, etc.) used directly across widgets rather than through `Theme.of(context)` lookups in most places — when changing brand colors, update the constants there rather than hunting through individual screens.
