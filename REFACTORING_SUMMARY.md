# UI Refactoring: Identified Foods Section

## Overview
Created a reusable `IdentifiedFoodsSection` component to unify the "Identified Foods" layout across AI Results and Meal Detail screens.

## Changes Made

### 1. **New File: `lib/widgets/identified_foods_section.dart`**
- **`IdentifiedFoodsSection` widget** - Container for the entire section
  - Takes a list of `FoodItem` objects and callbacks
  - Manages the section header (icon + title)
  - Renders food items with dividers between them
  
- **`FoodItemCard` widget** - Individual food item display
  - **Row 1**: Confidence dot + food info (left) | 2×2 macro grid (right)
    - Food name, portion description, confidence text, optional description
    - Nutrition display: Cal, P / C, F (color-coded)
  - **Row 2**: Edit button (left) | Weight stepper controls (right)
    - Edit button opens edit dialog
    - Weight adjustment: minus/plus buttons with ±10g increments

### 2. **Updated: `lib/screens/ai_results_screen.dart`**
- ✅ Replaced `_buildIdentifiedFoods()` to use `IdentifiedFoodsSection`
- ✅ Removed `_buildFoodItemDisplay()` method (now in reusable component)
- ✅ Removed `_buildLargeNutrientTag()` method (now in reusable component)
- ✅ Updated imports to include `identified_foods_section.dart`

### 3. **Updated: `lib/screens/meal_detail_screen.dart`**
- ✅ Replaced `_buildFoodItemsSection()` to use `IdentifiedFoodsSection`
- ✅ Removed `_buildWeightEditor()` method (now in reusable component)
- ✅ Removed `_buildMacroTag()` method (now in reusable component)
- ✅ Removed `FoodItemNutrientDisplay` class (now in reusable component)
- ✅ Updated imports to include `identified_foods_section.dart`

## Layout Details

### 2×2 Macro Grid Format
```
┌─────┬─────┐
│ Cal │  P  │
├─────┼─────┤
│  C  │  F  │
└─────┴─────┘
```

Each macro badge:
- Shows large, bold number
- Color-coded background (cal=red, protein=blue, carbs=green, fat=orange)
- Smaller label text below value
- Consistent 60px width with padding

### Weight Control Format
```
[ − ]  50g  [ + ]
```
- Buttons on either side
- Increments: ±10g per tap
- Bold, centered weight display

## Benefits
✅ **Single Source of Truth**: Future changes only need to be made once
✅ **Consistency**: Both screens use identical layout and styling
✅ **Maintainability**: Easier to refactor or enhance the component
✅ **Testability**: Component can be tested independently
✅ **Reusability**: Can be used in other screens if needed

## Files Modified
1. `lib/widgets/identified_foods_section.dart` (NEW)
2. `lib/screens/ai_results_screen.dart`
3. `lib/screens/meal_detail_screen.dart`

## Next Steps
1. Run `flutter pub get` to ensure dependencies are updated
2. Test on both AI Results and Meal Detail screens
3. Verify weight adjustments work correctly
4. Confirm the 2×2 macro grid matches the design mockup
