# Pulse Monetization Guide

## Current implementation status

The repository contains an in-app purchase paywall and three product identifiers:

| Product ID | Intended type | Current code path |
|---|---|---|
| `nabd_pro_monthly` | Auto-renewing monthly subscription | Queried and displayed; entitlement remains unverified |
| `nabd_pro_yearly` | Auto-renewing yearly subscription | Queried and displayed; entitlement remains unverified |
| `nabd_lifetime` | One-time non-consumable purchase | Queried, purchased, restored, and grants Pro for the current process after a store callback |

The paywall is available at `/paywall` and uses `in_app_purchase`. Product metadata and prices are fetched from Google Play Billing or App Store Connect; they are not hard-coded in the app.

## Important limitation

The current app does **not** implement a seven-day trial. It also does not persist or verify subscription entitlement. Monthly and yearly purchases are deliberately marked `subscriptionUnverified` in `lib/services/monetization_service.dart`, because a production app must validate receipts or purchase tokens through a trusted server or an approved entitlement service before granting access.

The current `canWriteEntry` limit is a local seven-entry limit, not a seven-day trial. It must not be described to users as a time-based trial.

## Recommended seven-day trial design

The recommended production design is to configure a **seven-day free trial on the monthly and/or yearly subscription base plan in the store**, rather than implementing a client-only timer. Google Play and App Store Connect then control eligibility, introductory-offer rules, billing, cancellation, and account-level trial abuse prevention.

The implementation sequence is:

1. Create the Android application in Google Play Console using the final package ID `com.nabd.journal`.
2. Create the subscriptions and base plans using the existing product IDs, or deliberately migrate to new Pulse-prefixed IDs before any public release.
3. Configure a seven-day free-trial offer on the selected subscription base plan.
4. Create the matching subscriptions in App Store Connect and configure the introductory offer there if iOS is supported.
5. Add a trusted receipt or purchase-token verification service. The service must verify product ID, package/bundle ID, purchase state, expiry time, acknowledgement, and trial/introductory-offer state.
6. Persist the verified entitlement server-side or in a signed entitlement cache. Never trust a local clock or a client-only `DateTime.now()` trial flag.
7. Treat an active seven-day trial as Pro, and remove Pro access after the verified expiry unless the store reports an active paid renewal.
8. Add restore-purchase and manage-subscription links, and test new account, previously-trialled account, cancellation, renewal, refund, grace period, and offline cases.

## Ads

The repository currently contains a rewarded-ad service only. It uses official Google test IDs in debug builds and expects production rewarded IDs through `--dart-define` in release builds. There is no complete banner/interstitial ad placement system in the current UI, and Pro is not currently used as a central ad-free gate.

Before commercial release:

- Create Android and iOS AdMob apps and production ad units.
- Put the native App IDs in `AndroidManifest.xml` and `Info.plist`.
- Pass platform-specific rewarded IDs at build time.
- Use test ads on test devices only.
- Gate every ad placement behind verified Pro entitlement so active Pro users see no ads.
- Complete the Google Play Data Safety and App Store privacy declarations consistently with the final behavior.

AdMob App IDs and ad-unit IDs are not server secrets; private verification keys and backend credentials must never be placed in the app.

## Product naming and package migration

The Android application ID is now `com.nabd.journal`. This is a new package identity from `com.productchat.studio.nabd`; Google Play treats it as a different application. If the old package has already been published, an in-place update requires retaining the old ID instead. Confirm the migration decision before creating the production listing.

## Test matrix before release

| Scenario | Expected result |
|---|---|
| Fresh install, no purchase | Free limits and no Pro-only access |
| Eligible new subscriber | Seven-day store trial grants verified Pro |
| Trial cancellation | Pro remains until verified trial expiry, then ends |
| Paid renewal | Pro remains active through verified expiry updates |
| Lifetime purchase | Pro remains active with no expiry |
| Restore purchase | Verified entitlement is restored |
| Refund/revocation | Pro is removed after the store/backend reports it |
| Debug build | Only Google test ads are used |
| Release without production IDs | Build should fail release validation, not silently ship test ads |
