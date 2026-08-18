# MPC: Mongolian Mining RWA App

A Flutter app for **MPC** (Bolor Geo MPC Corp.), the mining RWA issuance standard
infrastructure described in **MPC Whitepaper v1.1.0**.

Its job is narrow and deliberate: it is the **retail-facing verification window**
onto the issuance standard. It answers the whitepaper's own three questions for a
non-expert holder: *is this real, how far along is it, can it be trusted?*

> **Planning, roadmap and phasing live in Notion**, not in this repo.
> This README describes only what the code is and where it stands today.

## Wallet (branch `feature/wallet-integration`, 2026-07-30)

Non-custodial wallet, **testnet-only by construction**
(`ChainConfig` has no mainnet entry; nothing on this branch can sign against
chain ID 56):

- **Keys:** `WalletKeyService` — BIP-39 12-word create/import, BIP-44
  derivation at MetaMask's path. Interoperability is proven by unit tests
  against the two public reference vectors; the phrase this app
  creates restores the same address in MetaMask, and vice versa.
- **Storage:** seed only in platform secure storage on every platform,
  device-bound (`first_unlock_this_device`), excluded from backups
  (`allowBackup=false`). There is no plaintext fallback tier.
- **Screens:** FLAG_SECURE blocks screenshots/recording on the create/import
  flows (Android); iOS gap tracked in the compatibility checklist.
- **Chain:** `BscChainService` (BSC Testnet / Chapel) — balances, transfer
  history, and locally-signed ERC-20 sends with a pre-sign gas check.
  The test-MPC token address in `ChainConfig` is null until the Chapel deploy
  exists; balances read 0 and sends stay blocked until then.
- **Custody boundary:** the mnemonic never enters a network payload;
  only signed transactions reach the RPC.

Clean-room note: implementation references public BIP/EIP standards and
audited libraries only (`bip39`, `bip32`, `web3dart`, exact-pinned after
supply-chain review). No third-party wallet source was read or adapted.

## What this is not

- **Not a permissionless DeFi app.** "Mining" here is real physical mining
  (silicon, lithium, rare earths) tokenized as a Real World Asset. Not
  proof-of-work, not yield farming.
- **Not a custodial wallet.** Keys are generated and held on the user's device
  in platform secure storage, and transactions are signed locally. No server
  ever holds a key or a recovery phrase.
- **Not a source of investment claims.** The app publishes no price, no APY, no
  resource quantity, no grade, and no production figures.

## Current status (2026-07-29)

| Area | State |
| --- | --- |
| Asset browser, project detail, verification, governance, orchestration network | Built |
| Four-layer infrastructure model (Resource, Structuring, Tokenization, Capital markets) | Built |
| Localization: English, Korean, Mongolian, Chinese | Built (Mongolian needs native review) |
| Theming, routing, auth shell, onboarding | Built |
| Splash / unlock shell | Built |
| Wallet | **Real on-device keys, BSC Testnet only** (Jul 30, `feature/wallet-integration`): BIP-39 create/import + BIP-44 derivation (`m/44'/60'/0'/0/0`, MetaMask-interoperable, vector-tested), seed in hardened secure storage, transfers signed locally. Mainnet deliberately unreachable until the security review and independent audit are complete |
| Earn (staking / farming) | **Gated placeholder**, no rate shown, no whitepaper basis |
| Live chain data | **Wallet tab live on BSC Testnet** (BNB + test-MPC balance, transfer history, send) once a wallet exists; falls back to `MockMpcRepository` otherwise. Projects/content still mock pending the content service |

Nothing in the app is presented as verified. Per whitepaper Appendix D, no asset,
verification method or partner may render as complete until a signed artifact
exists, so every status reads *in discussion*, *design stage*, *to be
commissioned*, *provisionally selected*, or *planned*.

### Known gaps

1. **CI.** The compliance and wallet-flow tests are meant to run as
   failing-build gates; they are not wired to CI yet.
2. **Release signing.** The build reads `android/key.properties` when present,
   but no production keystore is configured yet; current builds are for
   internal testing via Firebase App Distribution only.
3. **Mongolian copy** needs a native-speaker review before release.

## Which MPC token does this app describe?

The app describes the MPC token on BNB Smart Chain, matching the official site.

| Token | Chain | Contract |
| --- | --- | --- |
| MPC | BNB Smart Chain | `0x9135709be5eB0f7d6B777b8d53a27B07e7d6107F` |

Chain facts live only in
[`lib/core/constants/mpc_facts.dart`](lib/core/constants/mpc_facts.dart),
guarded by a test tripwire so neither can change by a drive-by edit.

**ERC-3643** renders only as the *planned issuance standard*
("ERC-3643 · planned"), never as a property of the live token.

## Contributing

Code comments are limited to technical aspects: what the code does and why it
is written that way. Product claims render only through
[`lib/core/constants/mpc_facts.dart`](lib/core/constants/mpc_facts.dart) and
the localization tables, and [`test/product_claims_test.dart`](test/product_claims_test.dart)
verifies the UI states no price and fabricates no user data.

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
  --release-notes "v0.1.0+3 - BSC, Earn gated, KR/EN/MN/ZH"
```

The `--app` value is the app's Firebase App ID (Firebase Console →
Project settings → *Your apps*). Create the
`testers` group once under **App Distribution → Testers & Groups**, or swap
`--groups` for `--testers "a@example.com,b@example.com"`.

**Option B, console:** Firebase Console → App Distribution → *Distribute app* →
drag in `app-release.apk` → pick testers → Distribute.

### Signing

Release signing is configured through `android/key.properties`, which names
the keystore and holds its passwords; both stay out of the repository. See
[`android/key.properties.example`](android/key.properties.example) for the
expected keys. When the file is absent, a release build falls back to the
debug key and prints a warning; such an artifact is fine for local testing
but must not be distributed.

Google Sign-In is bound to the SHA-1 fingerprints registered in the Firebase
project. A build signed with an unregistered keystore fails sign-in with
`ApiException: 10` while guest mode keeps working. Register a keystore's
SHA-1 under Firebase Console → Project settings → *Your apps* → *Add
fingerprint*; print it with:

```bash
keytool -list -v -keystore <path-to-keystore> -alias <alias>
```

### iOS (Firebase App Distribution)

Bundle ID: `tech.globalmpc.mpcMiningApp`. Firebase config lives at
`ios/Runner/GoogleService-Info.plist` (not committed; download it from the
Firebase Console). You need a Mac with Xcode, an Apple
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
  --release-notes "v0.1.0+3 - BSC, Earn gated, KR/EN/MN/ZH"
```

The `--app` value is the app's Firebase App ID (Firebase Console →
Project settings → *Your apps*). Testers install via
the Firebase App Tester app (or the invite email link). Device UDIDs must be
registered in the Apple Developer portal for Ad Hoc builds.

**Option B, console:** Firebase Console → App Distribution → select the iOS app
→ *Distribute app* → drag in the `.ipa` → pick testers → Distribute.

TestFlight is a separate path (App Store Connect + App Store export method) and
is not required for Firebase App Distribution.

