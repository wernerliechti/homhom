# HOMs Optimization Guide

## Overview

This document describes the optimizations made to HOMs consumption and AI analysis rate limiting in the HomHom app.

## Changes Made

### 1. HOMs Only Consumed on Successful Analysis ✅

**Problem**: HOMs were consumed when the user clicked "Analyze" but before the AI analysis completed. If analysis failed, the HOM was wasted.

**Solution**: 
- Moved HOM consumption from `meal_metadata_screen.dart` to `ai_analysis_flow.dart`
- HOMs are now consumed ONLY when `AIResultsScreen` appears (analysis succeeded)
- Failed analyses don't consume HOMs

**Files Changed**:
- `lib/screens/meal_metadata_screen.dart`: Removed `consumeHomForScan()` call
- `lib/screens/ai_analysis_flow.dart`: Added HOM consumption logic in success path

**How It Works**:
```dart
// Before (❌ wasted HOMs on failure)
await homProvider.consumeHomForScan(); // Consumed here
await runAnalysis(); // Might fail

// After (✅ only consumed on success)
await runAnalysis(); // Might fail
if (success) {
  await homProvider.consumeHomForScan(); // Only if successful
}
```

---

### 2. Rate Limiting: 10 Requests Per Hour ✅

**Problem**: Users could drain AI credits by making unlimited analysis requests.

**Solution**:
- Added rate limiter in `HomService`: max 10 analysis requests per hour
- Both failed AND successful requests count towards the limit
- Timestamps stored locally for 1-hour sliding window
- Rate limit checked BEFORE analysis, prevents wasting HOMs

**Files Changed**:
- `lib/services/hom_service.dart`: Added rate limit logic
- `lib/providers/hom_provider.dart`: Exposed rate limit methods
- `lib/screens/meal_metadata_screen.dart`: Added rate limit check

**How It Works**:
```dart
// Check rate limit BEFORE sending to AI
final rateLimitResult = await homProvider.checkRateLimit();
if (!rateLimitResult.canMakeRequest) {
  show("Rate limit: 10 analyses per hour. Try again in X minutes.");
  return;
}

// Record the request (both success and failure count)
await homProvider.recordAnalysisRequest();
```

**Rate Limit Details**:
- **Limit**: 10 requests per hour (sliding window)
- **Scope**: Device-local (stored in secure storage)
- **Reset**: Automatic after 60 minutes
- **Returns**: Remaining requests + time until reset

---

### 3. Pre-Check: HOMs Balance Before Sending to AI ✅

**Problem**: User could start an analysis with insufficient HOMs, then on success, fail to consume (because balance was zero).

**Solution**:
- Added `canScan` check in `meal_metadata_screen.dart` BEFORE navigating to analysis
- If no HOMs available, show error and offer to navigate to purchase screen
- Prevents unnecessary AI requests

**Files Changed**:
- `lib/screens/meal_metadata_screen.dart`: Added pre-check before analysis

**How It Works**:
```dart
// Check if user has enough HOMs BEFORE sending to AI
if (!homProvider.canScan) {
  show("No HOMs remaining. Buy more to continue.");
  navigateToPurchaseScreen();
  return;
}

// Only proceed if balance is sufficient AND rate limit allows
const rateLimitResult = await homProvider.checkRateLimit();
if (!rateLimitResult.canMakeRequest) {
  show("Rate limit exceeded. Try again in X minutes.");
  return;
}

// Safe to proceed
navigateToAnalysis();
```

---

### 4. Improved Error Screens with 3 Categories ✅

**Problem**: Generic "Analysis Failed" message wasn't helpful. Users didn't know what went wrong.

**Solution**:
- Categorized errors into 3 types with specific messages:
  1. **No Food Detected** (photo clarity/quality issues)
  2. **AI Service Unavailable** (network/service down)
  3. **Something Went Wrong** (other errors)
- Each has specific, actionable advice
- Debug mode available (tap error icon 10x)

**Files Changed**:
- `lib/screens/ai_analysis_flow.dart`: Rewrote `_buildErrorScreen()`

**Error Types**:

#### Type 1: No Food Detected
```
Icon: image_not_supported_outlined
Message: "No Food Detected"
Description: "The photo wasn't clear enough, or we couldn't identify any food. Try:
• Take a clearer, well-lit photo
• Include more of the meal
• Make sure the food is in focus"
```

**Triggers When**:
- AI returns empty food list
- Image too dark/blurry
- No recognizable meal in photo

#### Type 2: AI Service Unavailable
```
Icon: cloud_off_outlined
Message: "AI Service Unavailable"
Description: "The AI analysis service is temporarily unavailable. This could be due to:
• Network connection issues
• Service is temporarily down
Please try again in a moment."
```

**Triggers When**:
- Network timeout or connection error
- Service returns 5xx error
- API unreachable

#### Type 3: Something Went Wrong (Other Errors)
```
Icon: warning_amber_rounded
Message: "Oops, Something Went Wrong"
Description: "We encountered an error while analyzing your meal. Please try again or contact us if the problem persists."
```

**Triggers When**:
- Any error not fitting the above categories

---

### 5. Debug Mode: Full Error Details ✅

**Feature**: Tap the error icon 10 times to see full error stack trace.

**Why**: Helps diagnose issues without exposing technical details to casual users.

**How It Works**:
```dart
// Track taps on error icon
GestureDetector(
  onTap: () {
    _errorIconTapCount++;
    if (_errorIconTapCount >= 10 && _fullErrorDetails != null) {
      _showDebugDialog(); // Show full error
      _errorIconTapCount = 0; // Reset
    }
  },
  child: Icon(...), // Error icon
)
```

**Debug Dialog Shows**:
- Full error message with stack trace
- "Copy" button to copy to clipboard
- Selectable text for screenshots

---

## Implementation Details

### Rate Limiting Storage

Timestamps stored locally in secure storage as comma-separated list:
```
Key: 'hom_analysis_timestamps'
Value: '1710907200000,1710907260000,1710907320000,...'
```

Each timestamp represents one analysis request. Timestamps older than 1 hour are automatically removed.

### HOM Consumption Flow

**Old Flow** (❌ Wasted HOMs on failure):
```
User clicks "Analyze"
  ↓
Metadata Screen checks HOMs & consumes ❌
  ↓
Analysis Flow starts
  ↓
Analysis fails
  ↓
HOM wasted! 😞
```

**New Flow** (✅ Only consumed on success with valid food data):
```
User clicks "Analyze"
  ↓
Metadata Screen checks:
  - Has HOMs? (canScan)
  - Rate limit OK? (checkRateLimit)
  ↓
Analysis Flow starts
  ↓
Analysis runs (no HOM yet!)
  ↓
Success with food data? Yes ✅
  → Consume HOM (consumeHomForScan) ⚠️ ONLY HERE
  → Record request (recordSuccessfulAnalysis)
  → Show results
  
Success? No ❌
  → Don't consume HOM
  → Don't record rate limit
  → Show error (HOM saved!)
```

**Key Points**:
1. ✅ **HOM consumed ONLY when**:
   - Analysis completes WITHOUT errors
   - AI returns valid food data (non-empty list)
   - HOM deduction succeeds

2. ✅ **HOM NOT consumed when**:
   - Network error
   - Auth failure
   - AI says "no food detected"
   - Any other error during analysis

3. ✅ **Rate limit recorded ONLY when**:
   - Analysis succeeds (HOM consumed)
   - Both success AND failure don't count towards rate limit separately
   - Only successful analyses count, preventing abuse

---

## Testing Checklist

- [ ] **HOM consumption timing**
  - [ ] Successful analysis consumes exactly 1 HOM
  - [ ] Failed analysis doesn't consume HOM
  - [ ] Balance UI updates correctly

- [ ] **Rate limiting**
  - [ ] User can make 10 analyses in an hour
  - [ ] 11th attempt is blocked with time message
  - [ ] Message shows correct remaining time
  - [ ] Limit resets after 1 hour

- [ ] **Pre-checks**
  - [ ] Zero HOMs: shows "Buy more" and navigates to purchase
  - [ ] Rate limited: shows time remaining and blocks analysis
  - [ ] Valid: allows analysis to proceed

- [ ] **Error screens**
  - [ ] No food error shows correct message
  - [ ] AI unavailable error shows correct message
  - [ ] Other errors show correct message
  - [ ] Debug mode works (tap icon 10x)
  - [ ] Copy button copies error details

---

## Future Improvements

1. **Server-side rate limiting**: Move from device-local to server-side for better security
2. **Rate limit reset notifications**: Notify user when their limit resets
3. **Premium unlimited tier**: Option to remove rate limit with subscription
4. **Analytics**: Track error types to identify common issues
5. **AI quality feedback**: Let users rate analysis quality to improve models

---

## Files Modified

```
lib/services/hom_service.dart          +130 lines (rate limiting)
lib/providers/hom_provider.dart        +15 lines (expose rate limit)
lib/screens/meal_metadata_screen.dart  +50 lines (pre-checks)
lib/screens/ai_analysis_flow.dart      +200 lines (success consumption + errors)
```

**Total**: ~395 lines added, 28 lines removed

**Commit**: `35f8ab0` (feature/hom-optimization branch)
