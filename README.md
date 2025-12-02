<div align="center">
  <img src="https://github.com/nyitgtm/FitRank/blob/main/FitRank/Assets.xcassets/fitrank_shield.imageset/fitrank_shield.png?raw=true" alt="FitRank Logo" width="100">
  <h1>FitRank iOS App</h1>
  
  [![Netlify Status](https://api.netlify.com/api/v1/badges/407eaca7-55a7-4e50-869f-7edadfcc2f72/deploy-status)](https://app.netlify.com/projects/fitrank/deploys)

  <p>
    <a href="https://apps.apple.com/us/app/fitrank-fitness-tracking/id6754830427">Download on the App Store</a>
  </p>
</div>

FitRank is a comprehensive fitness application designed to gamify the workout experience through community validation, competitive leaderboards, and integrated nutrition tracking. The application leverages a robust backend architecture using Firebase and Cloudflare R2 to support video-based workout logging, social interaction, and real-time data synchronization.

## Project Overview

The application is built using SwiftUI and follows the Model-View-ViewModel (MVVM) architectural pattern. It integrates deeply with Firebase services for authentication, database management, and server-side logic, while utilizing Cloudflare R2 for efficient and cost-effective video storage.

### Core Value Propositions

1.  **Community Validation**: A peer-review system where users upload workout videos that are voted on by the community. Valid lifts earn tokens and improve rankings.
2.  **Gamification**: Users earn tokens through engagement (uploading, voting, commenting) which can be spent in an Item Shop for cosmetic upgrades.
3.  **Team Competition**: Users join one of three teams (Killa Gorillas, Dark Sharks, Regal Eagles) to compete on global leaderboards.
4.  **Holistic Fitness**: Integrated nutrition tools including calorie calculation, meal logging, and progress tracking complement the workout features.

## Architecture and Technology Stack

### Frontend (iOS)
*   **Language**: Swift 5.8+
*   **UI Framework**: SwiftUI
*   **Architecture**: MVVM (Model-View-ViewModel)
*   **Concurrency**: Swift Concurrency (async/await)

### Backend (Firebase & Cloudflare)
*   **Authentication**: Firebase Auth (Email/Password)
*   **Database**: Cloud Firestore (NoSQL)
*   **Storage**: 
    *   **Cloudflare R2**: Primary storage for workout videos (S3-compatible).
    *   **Firebase Storage**: Secondary storage for static assets like post images.
*   **Serverless Logic**: Firebase Cloud Functions (Node.js)

## Feature Modules

### 1. Authentication & User Management
*   **Files**: `Authentication/`, `Models/User.swift`, `Repositories/UserRepository.swift`
*   **Functionality**: Handles user registration, login, and profile management.
*   **Data Model**: Users are stored in the `users` collection with attributes for team affiliation, token balance, and role (e.g., coach/admin).

### 2. Workout Feed & Validation
*   **Files**: `Views/TikTokFeedView.swift`, `Models/Workout.swift`, `Services/VoteService.swift`
*   **Functionality**: A scrolling feed similar to social media platforms. Users can view workout videos, vote (+1 for good form, -1 for bad form), and comment.
*   **Video Playback**: Custom `AVPlayer` implementation for seamless looping and playback control.
*   **Voting Logic**: Votes are transactional and update the workout's score in real-time. Cloud Functions monitor downvote ratios to automatically flag content for moderation.

### 3. Video Upload System
*   **Files**: `Services/VideoUploadService.swift`, `Services/SecureVideoUploadService.swift`, `Services/R2Config.swift`
*   **Functionality**: 
    *   Videos are compressed locally using `AVAssetExportSession` to optimize for mobile networks.
    *   Uploads are performed directly to Cloudflare R2 using AWS Signature V4 authentication or presigned URLs, bypassing the application server to reduce load and latency.
    *   Strict validation ensures videos meet duration (max 30s) and size constraints.

### 4. Community & Social
*   **Files**: `Views/CommunityView.swift`, `Views/CommunityBackendHook.swift`, `Models/Comment.swift`
*   **Functionality**: A general discussion board separate from the workout feed. Supports text and image posts, threading, and reporting.
*   **Teams**: Users are segmented into teams. Filters allow viewing content specific to "Killa Gorillas", "Dark Sharks", or "Regal Eagles".
*   **Moderation**: Comprehensive reporting system (`ReportService.swift`) and blocking capabilities (`UserRepository.swift`) ensure community safety.

### 5. Gamification & Shop
*   **Files**: `Views/ItemShopView.swift`, `Models/ShopModels.swift`, `Services/DailyTasksService.swift`
*   **Functionality**:
    *   **Tokens**: The virtual currency earned by receiving upvotes and completing daily tasks.
    *   **Item Shop**: Users can purchase cosmetic items such as Profile Themes, Badges, Titles, and custom App Icons.
    *   **Daily Tasks**: A rotating set of challenges (e.g., "Leave 3 comments", "Upload 1 workout") that reward engagement.

### 6. Nutrition & Progress
*   **Files**: `Views/Nutrition/`, `Views/ProgressTrackerView.swift`, `Views/Nutrition/FoodDatabase.swift`
*   **Functionality**:
    *   **Calorie Calculator**: Estimates TDEE (Total Daily Energy Expenditure) based on user metrics.
    *   **Meal Logger**: Tracks daily caloric and macronutrient intake.
    *   **Food Database**: Integrates with the USDA FoodData Central API for accurate nutritional information.
    *   **Progress Tracker**: Visualizes weight trends and calorie adherence over time, supporting both "Cutting" and "Bulking" goals.

### 7. Leaderboards & Gyms
*   **Files**: `Views/LeaderboardView.swift`, `Repositories/GymRepository.swift`
*   **Functionality**:
    *   **Global Leaderboard**: Ranks users by total tokens.
    *   **Gym Leaderboards**: Tracks "Gym Champions" for specific lifts (Bench, Squat, Deadlift) at physical gym locations.
    *   **Cloud Functions**: Automatically update gym records when a new personal best is verified.

## Backend Logic (Cloud Functions)

The `Firebase/functions/index.js` file contains critical server-side logic:

1.  **`flagLift`**: Monitors workout updates. If a video receives >100 views and has a downvote ratio >40%, it is automatically flagged for review.
2.  **`updateWorkoutVotes`**: Aggregates individual ratings from the `ratings` collection to update the summary counts on the `workout` document.
3.  **`grantTokens`**: Triggers on positive ratings. When a user receives an upvote, they are awarded 10 tokens.
4.  **`weeklyLeaderboardSnapshot`**: A scheduled job (Cron) that runs every Sunday to archive the current leaderboard state.
5.  **`updateGymChampion`**: Checks if a newly uploaded lift exceeds the current gym record for that lift type. If so, it updates the gym's "Best Lift" record.
6.  **`notifyAdminsOfReport`**: Listens for new documents in the `reports` collection to trigger administrative alerts.

## Security Rules (Firestore)

Access control is enforced via `firestore.rules`:
*   **Users**: Can only read/write their own profile data.
*   **Workouts**: Publicly readable. Creation requires authentication. Deletion is restricted to the owner or a coach.
*   **Ratings**: Users can create ratings but cannot modify them (preventing vote manipulation).
*   **Reports**: Only coaches can view reports. Any authenticated user can create a report.
*   **Gyms**: Only coaches can manage gym locations.

## Configuration

### Environment Variables
Sensitive configuration (API keys, R2 credentials) is managed via `Services/EnvironmentConfig.swift` which reads from a local `.env` file. This ensures secrets are not hardcoded in the repository.

### Dependencies
*   **Firebase iOS SDK**: Core backend services (Auth, Firestore, Storage).
*   **SDWebImage**: Efficient image loading and caching.
*   **Cloudflare R2**: Object storage for video content.

## Related Repositories

*   **Admin Website**: [FitRank-Website](https://github.com/nyitgtm/FitRank-Website) - The web-based admin portal for managing the FitRank platform.

## Getting Started

1.  **Prerequisites**: Xcode 15+, iOS 16+ Simulator/Device.
2.  **Configuration**:
    *   Ensure `GoogleService-Info.plist` is present in the root directory.
    *   Create a `.env` file with the required R2 credentials (see `EnvironmentConfig.swift`).
3.  **Installation**: Open `FitRank.xcodeproj` and let Swift Package Manager resolve dependencies.
4.  **Running**: Select a target simulator and press Run (Cmd+R).

---

*Note: This documentation reflects the current state of the codebase as of November 2025.*
