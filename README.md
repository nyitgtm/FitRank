# FitRank iOS App

FitRank is a community-driven fitness app that gamifies workout logging and peer validation of lifts. It combines video lift uploads, workout tracking, and team-based leaderboards, backed by Firebase services.

## Features

### 🏋️ Core Functionality
- **Video Workout Recording**: Record and upload workout videos with camera integration
- **Lift Validation**: Community rating system (+1/-1) for workout form validation
- **Team Competition**: Join one of three fixed teams (Killa Gorillas, Dark Sharks, Regal Eagles)
- **Gamification**: Token system for positive community engagement
- **GPS Tagging**: Automatic location tagging for gym-based features

### 🏆 Leaderboards
- **Global Leaderboard**: Rank all users by tokens earned
- **Team Leaderboard**: Compete within your team
- **Gym Leaderboard**: See top lifts at specific gym locations

### 👥 Community Features
- **Comments**: Add feedback and discussion to workouts
- **Reporting**: Flag inappropriate content for moderation
- **Coach System**: Special privileges for verified coaches
- **Content Moderation**: Automatic flagging of downvoted content

## Architecture

### MVVM Pattern
The app follows the Model-View-ViewModel architecture for clean separation of concerns:

- **Models**: Data structures for User, Workout, Rating, Comment, Gym, Report
- **ViewModels**: Business logic and state management (UserViewModel, WorkoutViewModel, etc.)
- **Views**: SwiftUI user interface components
- **Components**: Reusable UI elements (WorkoutCardView, TeamBadgeView, etc.)

### Firebase Integration
- **Authentication**: Email/password user management
- **Firestore**: NoSQL database for all app data
- **Storage**: Video file storage and management
- **Cloud Functions**: Automated backend workflows
- **Security Rules**: Comprehensive data access control

## Project Structure

```
FitRank/
├── Models/                 # Data models and enums
├── ViewModels/            # MVVM view models
├── Views/                 # Main app screens
├── Components/            # Reusable UI components
├── Firebase/              # Firebase configuration and rules
│   ├── firestore.rules    # Security rules
│   └── functions/         # Cloud Functions
├── Authentication/        # Auth-related views and managers
├── Assets.xcassets/       # App icons and images
└── Info.plist            # App permissions and configuration
```

## Data Models

### User
- Profile information (name, username, team)
- Role flags (coach, admin)
- Token balance for gamification

### Workout
- Video URL and metadata
- Weight, lift type, and location
- Community ratings and view counts
- Moderation status

### Rating
- User votes (+1/-1) on workouts
- Prevents duplicate voting
- Updates workout statistics

### Comment
- Text feedback on workouts
- Like/dislike system
- Moderation capabilities

## Firebase Schema

### Collections
- `/users/{userId}` - User profiles and settings
- `/workouts/{workoutId}` - Workout videos and metadata
- `/ratings/{ratingId}` - User ratings on workouts
- `/comments/{commentId}` - Comments on workouts
- `/gyms/{gymId}` - Gym locations and records
- `/reports/{reportId}` - Content moderation reports

### Security Rules
- Users can only modify their own data
- Public read access for published content
- Coach/admin privileges for moderation
- Rate limiting and validation rules

## Cloud Functions

### Automated Workflows
- **Content Moderation**: Flag workouts with >40% downvotes after 100 views
- **Token Distribution**: Award tokens for positive engagement
- **Leaderboard Snapshots**: Weekly leaderboard calculations
- **Gym Champions**: Update gym records for new personal bests

## Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 18.5+ deployment target
- Swift 5.8.1+
- Firebase project with iOS app configured

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/FitRank.git
   cd FitRank
   ```

2. **Install Firebase dependencies**
   - Add Firebase iOS SDK via Swift Package Manager
   - Include: FirebaseAuth, FirebaseFirestore, FirebaseStorage, FirebaseFunctions

3. **Configure Firebase**
   - Add `GoogleService-Info.plist` to the project
   - Update Firebase configuration in `FitRankApp.swift`

4. **Set up Cloud Functions**
   ```bash
   cd FitRank/Firebase/functions
   npm install
   firebase deploy --only functions
   ```

5. **Deploy Firestore Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

6. **Build and Run**
   - Open `FitRank.xcodeproj` in Xcode
   - Select target device/simulator
   - Build and run the project

### Required Permissions

The app requires the following permissions (configured in `Info.plist`):

- **Camera**: Video recording for workouts
- **Microphone**: Audio recording in videos
- **Location**: GPS tagging for gym locations
- **Photo Library**: Saving recorded videos

## Development Guidelines

### Code Style
- Follow SwiftUI best practices
- Use MVVM architecture consistently
- Implement proper error handling
- Add inline documentation for complex logic

### Testing
- Unit tests for ViewModels
- UI tests for critical user flows
- Integration tests for Firebase operations

### Performance
- Implement lazy loading for large lists
- Use Firebase offline persistence
- Optimize video uploads and streaming
- Cache frequently accessed data

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add tests and documentation
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions and support:
- Create an issue on GitHub
- Check the Firebase documentation
- Review SwiftUI and iOS development resources

## Roadmap

### Future Features
- Push notifications for engagement
- Advanced analytics and insights
- Social features (following, sharing)
- Integration with fitness trackers
- AR workout form analysis
- Multi-language support

---

**Built with ❤️ using SwiftUI and Firebase**
