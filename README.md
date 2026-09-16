# MPC Wallet

A Flutter **non-custodial wallet for the MPC mining-tokenization ecosystem**
(project entity: Bolor Geo MPC Corp.). Keys are generated and held on the
user's device and transactions are signed locally; no server ever holds a key
or a recovery phrase.

MPC is mining RWA **infrastructure**, not a single-country product. The
whitepaper describes a platform that connects verifiable mining projects to the
digital-asset ecosystem, and that scales from one reference project to shared
infrastructure. This app is the holder-facing surface of that platform: the
wallet you keep your own keys in, and the window you read the project record
through. It answers the whitepaper's three questions for a non-expert holder:
*is this real, how far along is it, can it be trusted?*

**Asset geography is a property of each project, never of the product.** The
first reference project is in Mongolia and Mongolian is one of four shipped app
languages. Neither bounds what the app supports, and no product-level string
may imply otherwise — [`test/product_definition_test.dart`](test/product_definition_test.dart)
enforces this.

> This README describes only what the code is and where it stands today.
> Product definition traces to the published whitepaper, not to internal plans.

## Four things called "MPC"

These are separate concepts and the app must never let one stand in for
another. Most product-copy mistakes in this repo have been a collapse of two
rows into one.

| Term | What it is | Where it lives here |
| --- | --- | --- |
| **MPC Wallet** | This app. Non-custodial: on-device keys, local signing. | all of `lib/` |
| **MPC** (the platform) | The mining RWA infrastructure — verification, structuring, tokenization, lifecycle management — described in the whitepaper. | rendered read-only from [`lib/core/constants/mpc_facts.dart`](lib/core/constants/mpc_facts.dart) and the projects feature |
| **$MPC** | The ecosystem utility token. Confers no ownership of any mine. | `MpcFacts` (symbol, planned supply, chain of record, contract) |
| **Asset tokens** | Per-project mining/RWA tokens issued against a verified project. **None exists.** | not implemented; the issuance standard renders as "ERC-3643 · planned" only |

## Wallet

Non-custodial wallet, **testnet-only by construction** (`ChainConfig` has no
mainnet entry; nothing here can sign against chain ID 56):

- **Keys:** `WalletKeyService` — BIP-39 12-word create/import, BIP-44
  derivation at MetaMask's path. Interoperability is proven by unit tests
  against the two public reference vectors; the phrase this app
  creates restores the same address in MetaMask, and vice versa.
- **Storage:** seed only in platform secure storage on every platform,
  device-bound (`first_unlock_this_device`), excluded from backups
  (`allowBackup=false`). There is no plaintext fallback tier.
- **Screens:** FLAG_SECURE blocks screenshots/recording on the create/import
  flows (Android). The iOS equivalent is still open; see Known gaps.
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

- **Not a single-country product.** "Mongolian" is a supported language and the
  location of the first reference project. It is not the product boundary.
- **Not a permissionless DeFi app.** "Mining" here is real physical mining
  (silicon, lithium, rare earths) tokenized as a Real World Asset. Not
  proof-of-work, not yield farming.
- **Not a custodial wallet.** Keys are generated and held on the user's device
  in platform secure storage, and transactions are signed locally. No server
  ever holds a key or a recovery phrase.
- **Not a source of investment claims.** The app publishes no price, no APY, no
  resource quantity, no grade, and no production figures.

## Current status (2026-09-16)

| Area | State |
| --- | --- |
| Asset browser, project detail, verification, governance, orchestration network | Built |
| Four-layer infrastructure model (Resource, Structuring, Tokenization, Capital markets) | Built |
| Localization: English, Korean, Mongolian, Chinese | Built (Mongolian needs native review) |
| Theming, routing, auth shell, onboarding | Built |
| Splash / unlock shell, biometric unlock, recovery-phrase screens | Built |
| Local notification centre | Built |
| Wallet | **Real on-device keys, BSC Testnet only**, on `main`: BIP-39 create/import + BIP-44 derivation (`m/44'/60'/0'/0/0`, MetaMask-interoperable, vector-tested), seed in hardened secure storage, transfers signed locally. Mainnet deliberately unreachable until the security review and independent audit are complete |
| Earn (staking / farming) | **Gated placeholder**, no rate shown, no whitepaper basis |
| Live chain data | **Wallet tab live on BSC Testnet** (BNB + test-MPC balance, transfer history, send) once a wallet exists; falls back to `MockMpcRepository` otherwise. Projects/content still mock pending the content service |
| Asset tokens, issuance, holding flow | **Not built.** Planned, and gated on the legal structure |

Nothing in the app is presented as verified. Per the whitepaper's disclosure
rules, no asset, verification method or partner may render as complete until a
signed artifact exists, so every status reads *in discussion*, *design stage*,
*to be commissioned*, *provisionally selected*, or *planned*.

### Known gaps

1. **Release signing.** The build reads `android/key.properties` when present,
   but no production keystore is configured in this repo; current builds are
   for internal testing only.
2. **Mongolian copy** needs a native-speaker review before release.
3. **iOS screenshot blocking.** Android has FLAG_SECURE on the seed flows; the
   iOS equivalent is still open.

## Which MPC token does this app describe?

$MPC on BNB Smart Chain. Chain facts live only in
[`lib/core/constants/mpc_facts.dart`](lib/core/constants/mpc_facts.dart),
guarded by a test tripwire so they cannot change by a drive-by edit.

| Item | Value |
| --- | --- |
| Symbol | MPC |
| Token type | Utility |
| Chain of record | BNB Smart Chain |
| Planned total supply | 10,000,000,000 |
| Contract | `0x9135709be5eB0f7d6B777b8d53a27B07e7d6107F` |

The published whitepaper (v1.7.0) states supply as **planned**, so the app
labels it "planned total supply" rather than presenting it as circulating.
**ERC-3643** renders only as the *planned issuance standard*
("ERC-3643 · planned"), never as a property of the live token.

## Naming and identifiers

The user-visible app name is **MPC**. The technical identifiers below still
carry the project's original working name. They are deliberately unchanged:
each one is a registration key for an external service, and renaming any of
them is a compatibility exercise with its own review, not a copy edit.

| Identifier | Value | Why it cannot change here |
| --- | --- | --- |
| Android `applicationId` | `tech.globalmpc.mpc_mining_app` | store listing and existing sign-in bindings |
| iOS bundle ID | `tech.globalmpc.mpcMiningApp` | Apple provisioning profiles |
| Dart package | `mpc_mining_app` | every `package:mpc_mining_app/...` import and test |

## Sources

Product claims in this app trace to material published by the project. Where
the published material is silent, the app says so instead of filling the gap.

| Source | Used for | Verified |
| --- | --- | --- |
| [MPC Whitepaper v1.7.0](https://www.globalmpc.tech/docs) | product definition, four-layer model, token type, planned supply, chain of record, disclosure rules | 2026-09-16 |
| [globalmpc.tech](https://www.globalmpc.tech/) | project entity, reference project, issuance-readiness statuses | 2026-09-16 |

## Contributing

Code comments are limited to technical aspects: what the code does and why it
is written that way. Product claims render only through
[`lib/core/constants/mpc_facts.dart`](lib/core/constants/mpc_facts.dart) and
the localization tables, and two tests hold the line:

- [`test/product_claims_test.dart`](test/product_claims_test.dart) — the UI
  states no price and fabricates no user data.
- [`test/product_definition_test.dart`](test/product_definition_test.dart) —
  no product-level string binds MPC to one country, and Mongolian support
  stays shipped.

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
    wallet/       entry flow, transfer screens, on-device wallet
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
- Tests assert the rules: no earn rate may contain a digit in any locale, no
  asset layer may read *secured* before a Competent Person report exists, and
  no product string may name a country.

## Run

```bash
flutter pub get
flutter run
flutter analyze     # 0 issues
flutter test        # formatters, facts, repository, honesty rules, localization
```

## Build and release

CI and distribution are owned by the shared **globalmpc** workflows. The files
in [`.github/workflows`](.github/workflows) only call into them:

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `quality-check.yaml` | PR and push to `main` | analyze + test gate |
| `dev.yaml` | manual, with a version input | build and distribute to develop |
| `prd.yaml` | manual, with a version input | build and distribute to production |

Both deploy workflows take Android and iOS toggles and a version string.
Release builds only: this app has no over-the-air patch channel. Signing
keys and store credentials are not in this repository.

### Bump the build number first

Distribution rejects a re-upload of an existing build number, so increment the
number after `+` in `pubspec.yaml` for every release:

```yaml
version: 0.1.0+4   # 0.1.0 = version name, 4 = build number
```

### Local release builds

```bash
flutter clean            # only needed after dependency or config changes
flutter pub get

flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk

cd ios && pod install && cd ..
flutter build ipa --release --export-method ad-hoc
# output: build/ios/ipa/*.ipa
```

Use `--split-per-abi` for smaller per-architecture Android APKs. iOS builds need
a Mac with Xcode, an Apple Developer account and a valid signing identity.

### Signing

Release signing reads `android/key.properties`, which names the keystore and
holds its passwords; both stay out of the repository. See
[`android/key.properties.example`](android/key.properties.example) for the
expected keys. When the file is absent, a release build falls back to the debug
key and prints a warning; such an artifact is fine for local testing but must
not be distributed.

Google Sign-In is bound to the SHA-1 of the signing key registered for
**globalmpc**. A build signed with an unregistered keystore fails sign-in with
`ApiException: 10` while guest mode keeps working. Print a keystore's SHA-1
with:

```bash
keytool -list -v -keystore <path-to-keystore> -alias <alias>
```

Platform client config is not committed. Use the **globalmpc** project
credentials already on your machine, or take them from the workflows secrets.
