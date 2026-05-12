# StoreKit Subscription System — Design Spec

**Date:** 2026-05-12
**Status:** Approved

---

## Overview

Drift uses a freemium model: 7 free AI dream interpretations, then a subscription is required. The Patterns feature is also subscription-only. Year in Dreams remains free. All monetisation is handled via StoreKit 2 — no server-side entitlement tracking.

---

## Product IDs

| Plan | Product ID |
|------|-----------|
| Monthly | `com.driftapp.pro.monthly` |
| Yearly | `com.driftapp.pro.yearly` |

---

## Gated Features

| Feature | Free | Pro |
|---------|------|-----|
| Dream recording + transcription | ✓ | ✓ |
| AI interpretation | 7 total | Unlimited |
| Patterns view | ✗ | ✓ |
| Year in Dreams | ✓ | ✓ |
| Journal / editing | ✓ | ✓ |

---

## Architecture

### New files

- `Drift/Services/StoreService.swift` — `@Observable` class owning all StoreKit logic
- `Drift/Views/Subscription/PaywallView.swift` — full-screen paywall sheet

### Modified files

- `DriftApp.swift` — inject `StoreService` into environment, start `Transaction.updates` listener
- `ContentView.swift` — lock badge on Patterns tab, paywall trigger on tap
- `RecordView.swift` — usage gate before interpretation
- `DreamEditView.swift` — usage gate before re-interpretation
- `PatternsView.swift` — locked placeholder when not subscribed
- `SettingsView.swift` — subscription status section

### Data flow

```
DriftApp
  └── StoreService (@Observable, injected via @Environment)
        ├── isSubscribed: Bool
        ├── products: [Product]          ← sorted yearly-first
        └── Transaction.updates task     ← long-lived, app lifetime

RecordView / DreamEditView
  └── @AppStorage("interpretationCount") Int
        └── count >= 7 && !isSubscribed → showPaywall = true
            else → interpret, then count += 1

PatternsView / ContentView tab
  └── !isSubscribed → lock badge + paywall on tap
```

---

## StoreService

```swift
@Observable
final class StoreService {
    private(set) var products: [Product] = []
    private(set) var isSubscribed: Bool = false

    private let productIDs = [
        "com.driftapp.pro.monthly",
        "com.driftapp.pro.yearly"
    ]

    func load() async                          // fetch products + check entitlement
    func purchase(_ product: Product) async throws
    func restorePurchases() async throws       // AppStore.sync() + checkEntitlement()
    func checkEntitlement() async              // queries Transaction.currentEntitlements
    func listenForTransactions() async         // Transaction.updates loop, app lifetime
}
```

- `load()` called once at app start
- `listenForTransactions()` runs as a `Task` in `DriftApp` for the app's lifetime — handles renewals, refunds, billing recovery in real time
- `purchase()` calls `product.purchase()`, then `checkEntitlement()` on `.success`
- `restorePurchases()` calls `AppStore.sync()` then `checkEntitlement()`
- Products sorted yearly-first for paywall display

---

## Usage Gate

- Key: `@AppStorage("interpretationCount")` — `Int`, default `0`
- Free limit: `7`
- Count incremented **after** a successful interpretation (user always gets their 7)
- Gate checked in both `RecordView.interpretDream()` and `DreamEditView.reinterpret()`
- Count never resets; once subscribed, `isSubscribed == true` bypasses the gate entirely
- `RecordView` interpret button shows a `"N free left"` badge when free interpretations remain and user is not subscribed

---

## PaywallView

Full-screen sheet, warm/narrative tone. Presented modally from `RecordView`, `DreamEditView`, and the Patterns tab. `PaywallView` accepts a `context` parameter (`interpretationLimit` or `patternsLock`) to adjust subtext.

**Layout (top to bottom):**
1. Dismiss button (top-right)
2. Moon emoji hero + headline `"Your dreams go deeper."` + context-specific subtext:
   - `interpretationLimit`: `"You've used your 7 free interpretations. Subscribe to keep exploring."`
   - `patternsLock`: `"Unlock pattern analysis and unlimited interpretations."`
3. Feature card (dark card, dividers): Unlimited interpretations · Patterns · Full symbol library
4. Side-by-side plan cards — Yearly (highlighted, shows per-month breakdown computed as `yearlyPrice / 12`) · Monthly
5. Subscribe CTA button (purple)
6. Footer: Restore purchases · Privacy

Prices fetched from StoreKit at runtime and displayed in the user's local currency. "Best value" badge on yearly plan.

---

## PatternsView Lock

- `ContentView` tab bar: lock icon badge overlaid on Patterns tab icon when `!storeService.isSubscribed`
- Tapping the locked tab opens `PaywallView` as a full-screen sheet; does not navigate to PatternsView
- `PatternsView` itself renders a locked placeholder (lock icon, description, "Unlock with Pro" button) when not subscribed — safety net in case the view is reached another way
- Lock badge and placeholder disappear immediately when `isSubscribed` flips to `true`

---

## SettingsView Integration

New **Subscription** section at the top of the settings list.

**Not subscribed:**
- Usage row: `"4 used · 3 left"` (derived from `interpretationCount`)
- `"Unlock Pro"` button → opens `PaywallView`
- `"Restore Purchases"` button

**Subscribed:**
- Status row: `"drift pro · Active"` with teal checkmark
- `"Manage Subscription"` button → deep-links to `https://apps.apple.com/account/subscriptions`

---

## Error Handling

- Product fetch failure: paywall shows a retry button; purchase buttons disabled
- Purchase cancelled by user: silent, no error shown
- Purchase failure (network, billing): error alert with retry option
- `restorePurchases()` with no active subscription: alert `"No active subscription found"`

---

## Out of Scope (v1)

- Server-side entitlement verification
- iCloud sync of interpretation count across devices
- Introductory offer / free trial UI
- Family sharing handling beyond what StoreKit provides automatically
