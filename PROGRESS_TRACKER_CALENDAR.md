# Progress Tracker - Calendar View Implementation

## New Features

### 📅 Calendar Week View
- **Main Display**: Each day shows:
  - Day of week and date
  - **Pounds lost per day** (calculated from calorie deficit)
  - Calories consumed
  - Calorie deficit/surplus with status emoji
  - Progress bar vs maintenance
  - Macro breakdown (P, C, F)

### 🔀 Week Navigation
- **Back Button** (◀️): Go to previous weeks
- **Date Display**: Shows week date range and week number
- **Next Button** (▶️): Go to forward weeks (disabled when on current week)
- Smooth navigation between all weeks with logged data

### ⚙️ Settings Button
- Located in **top right corner**
- Opens modal to adjust:
  - Daily Maintenance Calories (TDEE)
  - Target Weight Loss Per Week (1-2 lbs recommended)
  - Current Weight

### 📊 Stats Summary
- **Total Deficit**: Sum of all daily deficits for the week
- **Projected Weight Loss**: Total deficit ÷ 3,500 calories/lb
- **Daily Maintenance**: Your TDEE
- **Target Weight Loss**: Your weekly goal
- **Daily Deficit Needed**: Deficit required daily to hit goal
- **Target Daily Calories**: Maintenance - deficit needed

### 📍 Daily Status Indicators
Emojis show deficit quality:
- ⚠️ **Over** - Ate more than maintenance
- 📉 **Low** - Small deficit (< 200 cal)
- ✅ **Good** - Moderate deficit (200-500 cal)
- 🔥 **Great** - Large deficit (> 500 cal)

## How Weight Loss is Calculated

### Per Day
```
Weight Lost Per Day = Daily Calorie Deficit ÷ 3,500
Example: 500 cal deficit ÷ 3,500 = 0.14 lbs per day
```

### Per Week
```
Weekly Weight Loss = Sum of Daily Deficits ÷ 3,500
Example: 3,500 cal deficit ÷ 3,500 = 1 lb per week
```

## Data Sync Process

1. **App Launch** → Progress Tracker View loads
2. **onAppear** → `syncWithMealLogger()` is called
3. **Sync Logic**:
   - Reads all meal log dates
   - For each meal log without progress data:
     - Calculates calories consumed
     - Calculates deficit vs maintenance
     - Creates DailyProgress entry
   - Updates weekly summaries
4. **Storage** → Everything saved to UserDefaults
5. **Display** → Shows current week by default, allows navigation

## Files Modified

### ProgressTrackerView.swift
- Added `selectedWeekOffset` state for week navigation
- Added `WeekNavigationHeader` component
- Added `CalendarWeekView` for calendar grid layout
- Added `CalendarDayCell` showing pounds lost per day
- Moved settings button to top right (navigationBarHidden)
- Added proper week switching logic

### Models/ProgressTracker.swift
- Already has all calculations needed
- `dailyProgresses` tracks all days
- `getWeeklyProgress()` retrieves specific weeks

### ViewModels/ProgressTrackerViewModel.swift
- `syncWithMealLogger()` pulls Meal Logger data
- Automatically creates progress entries

## How to Use

1. **Open Progress Tracker** from Nutrition Hub
2. **See current week** with all daily data
3. **Adjust settings** via gear icon → set maintenance and weight loss goal
4. **Navigate weeks** with back/forward arrows
5. **View each day** showing:
   - Pounds lost that day
   - Calories consumed
   - Deficit status
   - Macro breakdown

## Storage

All data stored locally in UserDefaults:
- `progressTracker_data` contains all daily progress and settings
- Syncs with Meal Logger data automatically
- Persists across app sessions

## Features Working

✅ Calendar view shows daily data
✅ Pounds lost calculated per day
✅ Week navigation with arrows
✅ Settings button in top right
✅ Syncs with Meal Logger automatically
✅ Shows projected weight loss
✅ Local storage only
✅ Status emojis for deficit quality
✅ Macro breakdown per day
✅ Adjustable maintenance and goals
