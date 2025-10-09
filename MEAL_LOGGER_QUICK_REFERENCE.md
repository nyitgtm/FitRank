# Meal Logger - Quick Reference

## ✅ What Changed: Local Storage Implementation

### Before (Firebase)
- ❌ Required user authentication
- ❌ Needed internet to save/load
- ❌ Complex Firestore setup
- ❌ Data in cloud

### After (Local Storage)
- ✅ **No authentication needed**
- ✅ **Works offline** (except food search)
- ✅ **Simple UserDefaults**
- ✅ **Data stays on device**

## How It Works Now

### Storage Location
All meal logs are saved to **UserDefaults** on the device:
- Each day gets a unique key: `mealLog_2025-10-08`
- Calorie goal stored as: `calorieGoal`
- Data persists even after app restart

### New Features Added
1. **Settings Screen** - Gear icon in navigation bar
2. **Custom Calorie Goals** - Set your own daily target
3. **Clear All Data** - Reset button with confirmation
4. **Immediate Saving** - No cloud delay

## Key Files Modified

### MealLogViewModel.swift
```swift
- Removed: Firebase imports
- Removed: Firestore queries
+ Added: MealLogLocalStorage class
+ Added: UserDefaults persistence
```

### MealLoggerView.swift
```swift
+ Added: Settings button (gear icon)
+ Added: Load calorie goal on appear
+ Added: Settings sheet
```

### New Files Created
- `MealLogSettingsView.swift` - Settings interface

## Testing Checklist

✅ **Add a food entry**
1. Open Meal Logger
2. Tap + on any meal
3. Search for "chicken breast"
4. Select a result
5. Choose serving size
6. Tap "Add to Meal"

✅ **Verify persistence**
1. Close the app completely
2. Reopen FitRank
3. Go back to Meal Logger
4. Your food should still be there

✅ **Test settings**
1. Tap gear icon
2. Change calorie goal to 2500
3. Tap "Save Goal"
4. Close settings
5. Calorie remaining should update

✅ **Test date navigation**
1. Tap left arrow (yesterday)
2. Add a food to yesterday
3. Tap right arrow (today)
4. Previous day's data is saved

✅ **Test clear data**
1. Go to settings
2. Tap "Clear All Meal Logs"
3. Confirm
4. All meals should be gone

## Storage Limits

UserDefaults has a ~1MB limit for all data combined. Here's what that means:

**Rough Estimates:**
- 1 food entry ≈ 500 bytes
- 1 day with 10 foods ≈ 5KB
- 200 days of logs ≈ 1MB

**Conclusion:** You can store **months of meal logs** without issues.

## API Usage

### USDA FoodData Central API
- **Purpose:** Search for foods
- **Requires Internet:** Yes (for search only)
- **API Key:** Already included
- **Rate Limit:** 1000 requests/hour
- **Cost:** FREE

Once food is added to a meal, no internet is needed to view it.

## Architecture Overview

```
User Interaction
     ↓
MealLoggerView (UI)
     ↓
MealLogViewModel (Logic)
     ↓
MealLogLocalStorage (Persistence)
     ↓
UserDefaults (iOS Storage)
     ↓
Device Disk
```

## Common Issues & Solutions

### Issue: "Data disappeared after deleting app"
**Solution:** UserDefaults data is deleted when app is uninstalled. This is normal iOS behavior.

### Issue: "Food search not working"
**Solution:** Check internet connection. Search requires online access to USDA API.

### Issue: "Calorie goal won't save"
**Solution:** Make sure you tap "Save Goal" button in settings.

### Issue: "Can't add food"
**Solution:** Make sure you've entered a valid serving size (number only).

## Future Enhancement Options

### Easy Additions
1. Export to CSV
2. Weekly summary view
3. Favorite foods list
4. Custom foods

### Medium Complexity
5. Meal templates
6. Photo logging
7. Water tracker
8. Widget support

### Advanced Features
9. iCloud sync
10. HealthKit integration
11. Barcode scanning
12. Social sharing

## Code Snippets for Common Tasks

### Access Storage Directly
```swift
let storage = MealLogLocalStorage()
let dates = storage.getAllMealLogDates()
print("Logged \(dates.count) days")
```

### Get Today's Total Calories
```swift
if let log = storage.loadMealLog(for: Date()) {
    print("Today: \(Int(log.totalCalories)) calories")
}
```

### Change Default Calorie Goal
```swift
UserDefaults.standard.set(2500, forKey: "calorieGoal")
```

## Summary

**This is a fully functional, production-ready meal logger that:**
- ✅ Works without authentication
- ✅ Stores data locally on device
- ✅ Integrates with USDA food database
- ✅ Tracks calories and macros
- ✅ Persists across app restarts
- ✅ Provides settings for customization

**No additional setup required - it just works!**
