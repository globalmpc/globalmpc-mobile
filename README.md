# MPC: Mongolian Mining RWA App

A Flutter app for **MPC** (Bolor Geo MPC Corp.), the mining RWA issuance standard
infrastructure described in **MPC Whitepaper v1.1.0**.

Its job is narrow and deliberate: it is the **retail-facing verification window**
onto the issuance standard. It answers the whitepaper's own three questions for a
non-expert holder: *is this real, how far along is it, can it be trusted?*

> **Planning, roadmap and phasing live in Notion**, not in this repo.
> This README describes only what the code is and where it stands today.

## Wallet (branch `feature/wallet-integration`, 2026-07-30)

Non-custodial wallet per `docs/WALLET_SPEC.md`, **testnet-only by construction**
(`ChainConfig` has no mainnet entry; nothing on this branch can sign against
chain ID 56):

- **Keys:** `WalletKeyService` — BIP-39 12-word create/import, BIP-44
  derivation at MetaMask's path. Interoperability is proven by unit tests
  against the two public reference vectors (spec T2); the phrase this app
  creates restores the same address in MetaMask, and vice versa.
- **Storage:** seed only in platform secure storage, device-bound
  (`first_unlock_this_device`), excluded from backups (`allowBackup=false`,
  S4/S5). macOS dev builds are watch-only: the seed is never written there.
- **Screens:** FLAG_SECURE blocks screenshots/recording on the create/import
  flows (Android, S2); iOS gap tracked in the compatibility checklist.
- **Chain:** `BscChainService` (BSC Testnet / Chapel) — balances, transfer
  history, and locally-signed ERC-20 sends with a pre-sign gas check (T9).
  The test-MPC token address in `ChainConfig` is null until the Chapel deploy
  exists; balances read 0 and sends stay blocked until then.
- **Custody boundary (T16):** the mnemonic never enters a network payload;
  only signed transactions reach the RPC.

Clean-room note: implementation references public BIP/EIP standards and
audited libraries only (`bip39`, `bip32`, `web3dart` — exact-pinned after
supply-chain review, S7). No third-party wallet source was read or adapted.

## What this is not

- **Not a permissionless DeFi app.** "Mining" here is real physical mining
  (silicon, lithium, rare earths) tokenized as a Real World Asset. Not
  proof-of-work, not yield farming.
- **Not a custodial wallet.** The wallet screen is an explicitly-labelled demo.
  No keys are generated or stored. Real MPC lives in users' own wallets
  (MetaMask / Trust Wallet via WalletConnect, or on-device wallets); no server
  ever holds a key. An in-app non-custodial wallet is planned scope (plan P3).
- **Not a source of investment claims.** The app publishes no price, no APY, no
  resource quantity, no grade, and no production figures.

## Current status (2026-07-29)

| Area | State |
| --- | --- |
| Asset browser, project detail, verification, governance, orchestration network | Built |
| Four-layer infrastructure model (Resource, Structuring, Tokenization, Capital markets) | Built |
| Localization: English, Korean, Mongolian, Chinese | Built (Mongolian needs native review) |
| Theming, routing, auth shell, onboarding | Built |
| Splash / unlock shell | Built (design migration, Jul 29) |
| Wallet | **Real on-device keys, BSC Testnet only** (Jul 30, `feature/wallet-integration`): BIP-39 create/import + BIP-44 derivation (`m/44'/60'/0'/0/0`, MetaMask-interoperable, vector-tested), seed in hardened secure storage, transfers signed locally. Mainnet deliberately unreachable until the clean-room gates (WALLET_SPEC §5c / M2) pass |
| Earn (staking / farming) | **Gated placeholder**, no rate shown, no whitepaper basis |
| Live chain data | **Wallet tab live on BSC Testnet** (BNB + test-MPC balance, transfer history, send) once a wallet exists; falls back to `MockMpcRepository` otherwise. Projects/content still mock pending the content service (plan C1) |

Nothing in the app is presented as verified. Per whitepaper Appendix D, no asset,
verification method or partner may render as complete until a signed artifact
exists, so every status reads *in discussion*, *design stage*, *to be
commissioned*, *provisionally selected*, or *planned*.

### Design migration (2026-07-29)

Design team delivered a Flutter prototype as workspace folder
`globalMPC-flutter-full-source/` (read-only handoff snapshot). **Engineering
tree is this repo** (`mpc_mining_app`). Migrated into here (commit
`40a7584`): splash / unlock, wallet entry flow, send/transfer screens, theme /
font refresh, notifications shell, and related tests. `design-qa.md` in this
repo is a one-off Send-screen QA note — not product doctrine.

**Plane rule:** DappBay Users/TXN and waitlist on-chain check-in live in
`globalmpc-frontend`, not here. Do not expand Earn or invent yield to chase
listing metrics (see `mpc/20-ben-waitlist-onchain-feedback.md`).

### P0 readiness

The plan's P0 exit criteria are *project skeleton stands, status vocabulary
defined, compliance rules run as failing-build tests*. Against those:

| P0 epic | State |
| --- | --- |
| A1 App skeleton (shell, theming, onboarding, sign-in) | Done |
| A2 Localization framework (EN, KO, MN, ZH) | Done. Mongolian still needs native review before release |
| A3 Status vocabulary (no percentages, no `complete` value) | Done |
| A4 Compliance rules as failing-build tests | Tests exist (incl. wallet import / transfer). **Not yet wired to CI** |

Verified baseline 2026-07-20: `flutter analyze` 0 issues, honesty tests passing,
`flutter build apk --release` succeeds. Re-verify after the Jul 29 design
migration before calling P0 closed.

**Open before P0 can be called closed:**

1. **CI.** Compliance + wallet-flow tests should run as *failing-build* gates
   (git history now exists; wire CI next).
2. **Release signing.** Release builds use the debug keystore; see *Build and
   distribute* below for why that works today and what breaks off this machine.
3. **Design QA follow-through.** `design-qa.md` Send review was blocked on
   macOS screen-capture — confirm visually before stakeholder share.

Dependencies: `fl_chart` was removed earlier (orphaned). Keep `pubspec.yaml`
honest after design-font additions.

## Which MPC token does this app describe? (DEC-01: resolved, BSC)

**Resolved 2026-07-20: BSC for the app, not Polygon.**
The app describes the BSC token, matching the official site. On-chain state at
resolution time:

| Token | Chain | Contract | On-chain state (Jul 20 2026) |
| --- | --- | --- | --- |
| **App token (current)** | BNB Smart Chain | `0x9135709be5eB0f7d6B777b8d53a27B07e7d6107F` | 1 holder, 0 transfers, deployed Jul 3 |
| Legacy holder token | Polygon | `0x2d854416d2749b1f0eb8a4b2ab9027989f2ba262` | 89 holders, full payout history |

**Open follow-up (migration):** every pre-existing holder's MPC is on the
legacy Polygon contract, so their BSC balance is zero until a swap/migration is
defined. The balance UI must explain the migration state, never show a silent
zero to a real holder. The migration plan has been requested and is pending.
Chain facts live only in
[`lib/core/constants/mpc_facts.dart`](lib/core/constants/mpc_facts.dart),
guarded by a test tripwire against undecided edits.

Per DEC-02, **ERC-3643** renders only as the *planned issuance standard*
("ERC-3643 · planned"), never as a property of the live token.

## Architecture

Feature-first, layered, dependency-inverted, so the mock data source is replaced
by a real chain/API client by changing **one line** in [`lib/app.dart`](lib/app.dart).

```text
lib/
  main.dart                 app entry
  app.dart                  providers + MaterialApp.router (repo injected here)
  core/
    constants/mpc_facts.dart   single source of truth for MPC facts + statuses
    constants/earn_facts.dart  gated earn capabilities (no rates by construction)
    localization/strings/      en · ko · mn · zh, en is the source of truth
    theme/ router/ state/ utils/ widgets/
  data/
    models/                    MiningProject, VerificationMethod, wallet models
    repositories/              MpcRepository (interface) + MockMpcRepository
  features/
    onboarding/   splash, unlock, onboarding
    dashboard/ projects/ earn/
    wallet/       entry flow, transfer screens, demo wallet
    notifications/ settings/ shell/ web/
```

Bottom-nav: **Home · Projects · Earn · Wallet**.

- **State:** `provider` + `ChangeNotifier`, one per feature, each holding a typed
  `ViewState<T>`.
- **Routing:** `go_router` `StatefulShellRoute`; each tab keeps its own stack.
- **Theme:** light + dark via an `AppPalette` theme extension; widgets read
  `context.palette` and never branch on brightness.
- **Data boundary:** UI depends only on the `MpcRepository` interface.

### How honesty is enforced in code, not by review

The whitepaper's disclosure rules are structural, so they cannot be edited away:

- Progress is a **status enum** (`LayerStatus`, `CommissionStatus`), never a
  percentage. The whitepaper never expresses progress numerically.
- `CommissionStatus` deliberately has **no `complete` value**. One gets added when
  a signed report or third-party-reviewed PoC exists to back it.
- Every `VerificationMethod` carries its status, so CCTV/AI can never render
  without its *design stage* label.
- Tests assert the rules: no earn rate may contain a digit in any locale, and no
  asset layer may read *secured* before a Competent Person report exists.

## Run

```bash
flutter pub get
flutter run
flutter analyze     # 0 issues
flutter test        # formatters, facts, repository, honesty rules, localization
```

## Build and distribute (Firebase App Distribution)

The app ships to reviewers through **Firebase App Distribution** on project
`globalmpc-app`. Nothing here needs a Play Store account.

### 1. Bump the build number

App Distribution rejects a re-upload of an existing build number, so increment
the number after `+` in `pubspec.yaml` every time:

```yaml
version: 0.1.0+3   # 0.1.0 = version name, 3 = build number
```

### 2. Build the release APK

```bash
flutter clean            # only needed after dependency or config changes
flutter pub get
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

Use `--split-per-abi` if you want smaller per-architecture APKs; the single fat
APK above is simpler for reviewers and is what the commands below assume.

### 3. Upload

**Option A, command line** (repeatable, preferred):

```bash
# once per machine
npm install -g firebase-tools
firebase login

firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app 1:784029347956:android:5f7bf2d515e0b7b888e121 \
  --groups "testers" \
  --release-notes "v0.1.0+3 — BSC per DEC-01, Earn gated, KR/EN/MN/ZH"
```

The `--app` value is the Android app ID from `firebase.json`. Create the
`testers` group once under **App Distribution → Testers & Groups**, or swap
`--groups` for `--testers "a@example.com,b@example.com"`.

**Option B, console:** Firebase Console → App Distribution → *Distribute app* →
drag in `app-release.apk` → pick testers → Distribute.

### Signing: read this before distributing widely

`android/app/build.gradle.kts` currently signs release builds with the **debug**
keystore (the Flutter template default, `// TODO: Add your own signing config`).

That works today, and Google Sign-In works with it, for one specific reason: the
certificate hash registered in `android/app/google-services.json`
(`6673f918…26ed5b09`) is the SHA-1 of the local `~/.android/debug.keystore`.

The consequence: **builds from any other machine or from CI will have a different
SHA-1, and Google Sign-In will fail on them** (sign-in returns
`ApiException: 10`). Guest mode still works, so the app remains testable.

Before the app goes beyond your own machine, create a release keystore, point the
release `signingConfig` at it, and register its SHA-1 in Firebase Console →
Project settings → *Your apps* → *Add fingerprint*. Get the SHA-1 with:

```bash
keytool -list -v -keystore <path-to-keystore> -alias <alias>
```

Keep the keystore and its passwords out of the repo (`key.properties`,
gitignored). This is tracked as a P0 exit item below.

### iOS (Firebase App Distribution)

Bundle ID: `tech.globalmpc.mpcMiningApp`. Firebase config is already in
`ios/Runner/GoogleService-Info.plist`. You need a Mac with Xcode, an Apple
Developer account, and a valid signing identity (Ad Hoc or Development
provisioning profile) before these commands succeed.

#### 1. Bump the build number

Same as Android — increment the number after `+` in `pubspec.yaml`.

#### 2. Build the release IPA

```bash
flutter clean            # only needed after dependency or config changes
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
# output: build/ios/ipa/*.ipa
```

If Xcode asks for an export method, use **Ad Hoc** for Firebase App
Distribution (not App Store). You can also pass it explicitly once export
options are set up:

```bash
flutter build ipa --release --export-method ad-hoc
```

#### 3. Upload

```bash
firebase appdistribution:distribute \
  build/ios/ipa/*.ipa \
  --app 1:784029347956:ios:623f814980e570f388e121 \
  --groups "testers" \
  --release-notes "v0.1.0+3 — BSC per DEC-01, Earn gated, KR/EN/MN/ZH"
```

The `--app` value is the iOS app ID from `firebase.json`. Testers install via
the Firebase App Tester app (or the invite email link). Device UDIDs must be
registered in the Apple Developer portal for Ad Hoc builds.

**Option B, console:** Firebase Console → App Distribution → select the iOS app
→ *Distribute app* → drag in the `.ipa` → pick testers → Distribute.

TestFlight is a separate path (App Store Connect + App Store export method) and
is not required for Firebase App Distribution.

## Decision record

`docs/PRODUCT_DECISION.md` (internal, not in the repository) records how the
"mining DApp" request was reconciled with what MPC actually is, and why this is
a standalone app rather than a feature inside an existing wallet.
