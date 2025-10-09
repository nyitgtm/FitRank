# Meal Logger Feature - LOCAL STORAGE Implementation

## Overview
A comprehensive meal logging system similar to MyFitnessPal has been implemented for the FitRank app. Users can track their daily food intake across four meal categories: Breakfast, Lunch, Dinner, and Snacks. **All data is stored locally on the device using UserDefaults.**

## Storage Architecture

### Local Storage (UserDefaults)
✅ **No Authentication Required** - Works immediately without login
✅ **Instant Save/Load** - Data persists on device restart
✅ **Privacy First** - All data stays on the user's device
✅ **Automatic Syncing** - UserDefaults automatically synchronizes

### Storage Structure
```
UserDefaults Keys:
- mealLog_2025-10-08: DailyMealLog (JSON encoded)
- mealLog_2025-10-09: DailyMealLog (JSON encoded)
- calorieGoal: Int (2000 default)
```

## Files Created

### 1. Models/MealLog.swift
Defines the data structures for meal logging:
- **MealType**: Enum for Breakfast, Lunch, Dinner, Snacks with associated icons
- **FoodEntry**: Individual food item with nutritional information and serving size
- **DailyMealLog**: Daily log containing all meals with computed totals for calories and macros

### 2. ViewModels/MealLogViewModel.swift
Manages the meal logging state and **local storage**:
- Loads and saves daily meal logs to UserDefaults
- Handles adding/removing food entries
- Calculates remaining calories and progress
- Manages date navigation
- **MealLogLocalStorage** class handles all persistence

### 3. Views/Nutrition/MealLoggerView.swift
Main meal logger interface featuring:
- **Date navigation** (previous/next day with visual indicators)
- **Calorie summary card** with circular progress indicator
- **Macro breakdown** (Protein, Carbs, Fat)
- **Four meal sections** with add buttons
- **Individual food entries** with delete functionality
- **Settings button** (gear icon) in navigation bar

### 4. Views/Nutrition/AddFoodView.swift
Food search and entry interface:
- **Search integration** with USDA FoodData Central API
- **Serving size input** with customizable amounts
- **Quick amount buttons** (50g, 100g, 150g, 200g)
- **Live nutrition preview** that updates as serving size changes
- **Unit selection** (grams, oz, serving)

### 5. Views/Nutrition/MealLogSettingsView.swift
Settings and configuration:
- **Set custom calorie goals** (saved to UserDefaults)
- **Clear all meal logs** with confirmation alert
- **View storage info** (shows it's local device storage)
- **USDA attribution**

## Features

### ✅ Local Storage Benefits
- **Works Offline** - No internet needed after initial food search
- **No Account Required** - Start using immediately
- **Fast Performance** - Instant load/save times
- **Private** - Data never leaves the device
- **Reliable** - UserDefaults is native iOS storage

### Daily Tracking
- View and log meals for any date
- Navigate between days easily
- Auto-saves to device storage
- Data persists across app restarts

### Calorie & Macro Tracking
- Visual calorie progress with color coding:
  - Green: 200+ calories remaining
  - Orange: <200 calories remaining
  - Red: Over calorie goal
- Real-time macro totals (Protein, Carbs, Fat)
- Tracks both consumed and goal calories
- **Customizable calorie goals via settings**

### Food Entry
- Search 25+ results from USDA database
- Shows nutritional info for each food
- Adjustable serving sizes
- Displays scaled nutrition based on serving
- Brand information when available

### Meal Organization
- Four meal categories with custom icons
- Shows total calories per meal
- Easy add/delete functionality
- Clean, organized interface

## Local Storage Manager Functions

```swift
class MealLogLocalStorage {
    func saveMealLog(_ log: DailyMealLog) throws
    func loadMealLog(for date: Date) -> DailyMealLog?
    func deleteMealLog(for date: Date)
    func getAllMealLogDates() -> [Date]
    func clearAllMealLogs()
}
```

## User Flow
1. Navigate to Nutrition Hub
2. Tap "Meal Logger" card
3. Select date (defaults to today)
4. Tap "+" on any meal section
5. Search for food (requires internet)
6. Tap food from results
7. Adjust serving size
8. Tap "Add to Meal"
9. **Data automatically saves to device**
10. Tap gear icon for settings

## Settings Features
- **Set Calorie Goal**: Customize your daily target
- **Clear All Data**: Remove all meal logs with confirmation
- **Storage Info**: Shows data is stored locally
- **Data Source**: Credits USDA FoodData Central

## Data Persistence
- All meal logs stored as JSON in UserDefaults
- Keys formatted as: `mealLog_YYYY-MM-DD`
- Calorie goal stored separately: `calorieGoal`
- UserDefaults.synchronize() ensures immediate save
- Data survives app closure and device restart

## Migration Path (Optional Future Enhancement)
If you later want to add cloud sync:
1. Keep local storage as fallback
2. Add Firebase sync in background
3. Use local data as source of truth
4. Sync to cloud when authenticated
5. Merge data on login

## Limitations of Local Storage
- Data only on this device (no cross-device sync)
- Data lost if app is deleted
- No backup/restore built-in
- Limited to ~1MB total for all UserDefaults

## Advantages of This Approach
✅ **Works immediately** - No Firebase setup needed
✅ **No authentication** - Use without login
✅ **Fast** - Instant read/write
✅ **Private** - Data stays on device
✅ **Simple** - Less complexity than cloud sync
✅ **Reliable** - Native iOS storage mechanism

## Testing the Feature
1. Open the app (no login required!)
2. Navigate to Nutrition Hub
3. Tap "Meal Logger"
4. Add some foods to different meals
5. Close the app completely
6. Reopen the app
7. Navigate back to Meal Logger
8. ✅ All your data is still there!

## Next Steps (Optional Enhancements)
1. Export meal logs to CSV
2. Weekly/monthly statistics view
3. Favorite foods list (also local)
4. Meal templates/recipes
5. Photo logging
6. Water intake tracker
7. Barcode scanning
8. iCloud backup option
9. Health app integration
10. Widget for quick logging

## Technical Notes
- Uses Codable for JSON encoding/decoding
- ISO8601 date encoding for consistency
- Type-safe storage with Swift generics
- Error handling with Swift's Result type
- SwiftUI @Published for reactive updates
