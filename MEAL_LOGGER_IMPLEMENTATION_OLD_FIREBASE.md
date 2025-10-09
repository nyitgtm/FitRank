# Meal Logger Feature - Implementation Summary

## Overview
A comprehensive meal logging system similar to MyFitnessPal has been implemented for the FitRank app. Users can now track their daily food intake across four meal categories: Breakfast, Lunch, Dinner, and Snacks.

## Files Created

### 1. Models/MealLog.swift
Defines the data structures for meal logging:
- **MealType**: Enum for Breakfast, Lunch, Dinner, Snacks with associated icons
- **FoodEntry**: Individual food item with nutritional information and serving size
- **DailyMealLog**: Daily log containing all meals with computed totals for calories and macros

### 2. ViewModels/MealLogViewModel.swift
Manages the meal logging state and Firebase integration:
- Loads and saves daily meal logs to Firestore
- Handles adding/removing food entries
- Calculates remaining calories and progress
- Manages date navigation
- Stores data in: `users/{userId}/mealLogs/{date}`

### 3. Views/Nutrition/MealLoggerView.swift
Main meal logger interface featuring:
- **Date navigation** (previous/next day with visual indicators)
- **Calorie summary card** with circular progress indicator
- **Macro breakdown** (Protein, Carbs, Fat)
- **Four meal sections** with add buttons
- **Individual food entries** with delete functionality

### 4. Views/Nutrition/AddFoodView.swift
Food search and entry interface:
- **Search integration** with USDA FoodData Central API
- **Serving size input** with customizable amounts
- **Quick amount buttons** (50g, 100g, 150g, 200g)
- **Live nutrition preview** that updates as serving size changes
- **Unit selection** (grams, oz, serving)

## Features

### Daily Tracking
- View and log meals for any date
- Navigate between days easily
- Auto-saves to Firebase
- Per-user meal logs stored separately

### Calorie & Macro Tracking
- Visual calorie progress with color coding:
  - Green: 200+ calories remaining
  - Orange: <200 calories remaining
  - Red: Over calorie goal
- Real-time macro totals (Protein, Carbs, Fat)
- Tracks both consumed and goal calories

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

## Firebase Structure
```
users/
  {userId}/
    mealLogs/
      {yyyy-MM-dd}/
        id: String
        userId: String
        date: Timestamp
        breakfast: [FoodEntry]
        lunch: [FoodEntry]
        dinner: [FoodEntry]
        snacks: [FoodEntry]
```

## User Flow
1. Navigate to Nutrition Hub
2. Tap "Meal Logger" card
3. Select date (defaults to today)
4. Tap "+" on any meal section
5. Search for food
6. Tap food from results
7. Adjust serving size
8. Tap "Add to Meal"
9. View updated totals

## Integration
- Linked from NutritionMainView
- Uses existing Food models from FoodDatabase.swift
- Integrates with Firebase Authentication
- Follows app's design patterns

## Next Steps (Optional Enhancements)
1. Connect with CalorieCalculatorView to set personalized calorie goals
2. Add meal history view
3. Implement favorite foods for quick logging
4. Add barcode scanning
5. Weekly/monthly statistics
6. Custom food creation
7. Meal templates/recipes
8. Photo logging
9. Water intake tracking
10. Export functionality

## Notes
- Default calorie goal is set to 2000 (can be customized)
- All nutritional data is per 100g from USDA API
- Serving sizes are scaled automatically
- Data persists in Firestore for cross-device sync
