# Drift App Improvements — Design Spec
**Date:** 2026-05-06
**Scope:** Option B — Bug fixes + deduplication + targeted UX polish

---

## 1. Bug Fixes

### 1a. Emotional arc chart — missing series (PatternsView)
**File:** `Drift/Views/Patterns/PatternsView.swift`

The `emotionalArc` data already computes `.vivid` and `.uncertain` per month, but `emotionalArcChart` only renders two `AreaMark` series (Tension, Calm). The legend shows four items, making Vivid and Uncertain appear broken.

**Fix:** Add two more `AreaMark` entries:
- Vivid → `Color.white.opacity(0.6)`
- Uncertain → `Color.driftAmber.opacity(0.5)`

### 1b. Outdated Claude model version (ClaudeService)
**File:** `Drift/Services/ClaudeService.swift`, line 105

Change `"claude-sonnet-4-5"` → `"claude-sonnet-4-6"`.

---

## 2. Deduplication & Code Quality

### 2a. Shared ModePickerView component
**New file:** `Drift/Views/Shared/ModePickerView.swift`

Extract the three-capsule interpretation mode picker into a standalone view:
```swift
ModePickerView(selected: $mode)  // Binding<String>
```

The `InterpretationMode` enum (currently private to `RecordView`) moves into this file so both `RecordView` and `DreamEditView` can use it. All three inline picker occurrences (RecordView `recordingBody`, RecordView `transcribedView`, DreamEditView) are replaced with `ModePickerView`.

### 2b. Remove `driftTagTeal` alias (DriftColors)
**File:** `Drift/Views/Shared/DriftColors.swift`

`driftTagTeal` and `driftTeal` are identical (`#4DD9C0`). Remove `driftTagTeal`; replace all usages with `driftTeal`.

### 2c. Add `driftYellow` to design system (DriftColors)
**File:** `Drift/Views/Shared/DriftColors.swift`

Add `static let driftYellow = Color(hex: "#F5E642")`. Replace the hardcoded `Color(hex: "#F5E642")` in `RecordView`'s "Type instead" button with `.driftYellow`.

### 2d. Cache expensive computed properties (JournalView)
**File:** `Drift/Views/Journal/JournalView.swift`

`grouped` and `totalSymbols` are computed vars that re-run on every SwiftUI render pass. Both depend only on `dreams` (a `@Query` result). Refactor to `@State` private vars, updated via `.onChange(of: dreams)` and on `.onAppear`. This avoids redundant Dictionary grouping and Set construction on every frame.

### 2e. LoadingView — use `.task` modifier
**File:** `Drift/Views/Reflection/LoadingView.swift`

Replace the two manual `Task { @MainActor in while !Task.isCancelled }` blocks (dot cycling and message cycling) with two `.task` modifiers on the view. SwiftUI's `.task` automatically cancels on disappear, removing the need for manual `dotTask`/`messageTask` state vars and the `onDisappear` cleanup.

---

## 3. UX Polish

### 3a. Haptic feedback on recording (RecordView)
**File:** `Drift/Views/Record/RecordView.swift`

- `startRecording()`: fire `UIImpactFeedbackGenerator(style: .medium).impactOccurred()` after the recorder starts successfully.
- `stopAndTranscribe()`: fire `UIImpactFeedbackGenerator(style: .light).impactOccurred()` immediately when stop is called.

No new state required.

### 3b. Better zero-state copy (MoonPhaseCard)
**File:** `Drift/Views/Tonight/MoonPhaseCard.swift`

- Streak display: when `streak == 0`, show `"Start tonight"` (font `.outfit(13)`) instead of `"0"` + `"days"`.
- Last night display: when `lastNightCount == 0`, show `"—"` instead of `"0"`.

### 3c. Patterns lock screen teaser (PatternsView)
**File:** `Drift/Views/Patterns/PatternsView.swift`

Below the `"Record X more dreams"` line in `lockedView`, add:
```
"Unlock: recurring symbols · emotional arc · dominant feelings"
```
Styled `.outfit(12)`, `.driftTeal.opacity(0.6)`. Gives users a concrete reason to keep recording.

---

## Files Changed Summary

| File | Change |
|------|--------|
| `Services/ClaudeService.swift` | Model version bump |
| `Views/Shared/DriftColors.swift` | Remove `driftTagTeal`, add `driftYellow` |
| `Views/Shared/ModePickerView.swift` | New shared component |
| `Views/Record/RecordView.swift` | Use `ModePickerView`, add haptics, use `.driftYellow` |
| `Views/Journal/DreamEditView.swift` | Use `ModePickerView` |
| `Views/Journal/JournalView.swift` | Cache `grouped` + `totalSymbols` |
| `Views/Patterns/PatternsView.swift` | Fix chart, add lock teaser |
| `Views/Reflection/LoadingView.swift` | `.task` modifier refactor |
| `Views/Tonight/MoonPhaseCard.swift` | Zero-state copy |
