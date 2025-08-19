# HOPES - Grade 7 E-Learning Platform

A production-ready, offline-first Flutter e-learning application designed for Grade 7 students. This app provides a comprehensive learning experience with local content management, adaptive learning tracks, and progress tracking.

## Features

### Phase 1 (Current)
- **Offline-first architecture** with local SQLite database
- **Mock authentication** with role-based access (Student/Teacher)
- **Local content management** with seeded Grade 7 Science curriculum
- **Adaptive learning tracks** (Remedial/Core/Advanced) based on pre-assessment
- **Interactive lesson reader** with Markdown support
- **Quiz engine** with multiple-choice questions and scoring
- **Progress tracking** with lesson status and performance metrics
- **Responsive Material 3 UI** with light/dark theme support

### Phase 2 (Implemented) ✅
- **Teacher Panel**: Complete CRUD operations for content management
  - Create, edit, and delete subjects, modules, lessons, and quizzes
  - WYSIWYG markdown editor for lessons
  - Multiple-choice quiz editor with validation
- **Sync Engine**: Offline-first synchronization system
  - Content sync service for teacher uploads
  - Progress sync service for student data
  - Queue system for offline changes
  - Sync status indicators
- **Gamification**: Student engagement features
  - Points system (awarded after quizzes)
  - Badge system with automatic awarding
    - Starter Badge (first quiz completed)
    - Achiever Badge (3 scores ≥ 85%)
    - Consistency Badge (7-day streak)
  - Progress tracking with visual indicators
- **Teacher Monitoring**: Student progress analytics
  - Class overview with statistics
  - Individual student progress tracking
  - Subject-wise completion percentages
  - Badge and points monitoring

## Tech Stack

- **Framework**: Flutter (stable)
- **Language**: Dart (null-safe)
- **State Management**: Riverpod with hooks_riverpod
- **Database**: Drift (SQLite)
- **Routing**: Go Router
- **Code Generation**: Freezed + json_serializable
- **UI**: Material 3 with responsive design
- **Testing**: flutter_test + mocktail

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/                     # Core utilities and configuration
│   ├── theme.dart           # Material 3 theme configuration
│   ├── routing.dart         # Go Router configuration
│   ├── providers.dart       # Riverpod dependency injection
│   ├── auth_notifier.dart   # Authentication state management
│   └── result.dart          # Result types for error handling
├── data/                    # Data layer
│   ├── db/                  # Database layer
│   │   ├── database.dart    # Drift database schema
│   │   └── seed_importer.dart # Seed data importer
│   ├── models/              # Freezed data models
│   │   ├── user.dart
│   │   ├── subject.dart
│   │   ├── module.dart
│   │   ├── lesson.dart
│   │   ├── assessment.dart
│   │   ├── attempt.dart
│   │   ├── progress.dart
│   │   ├── badge.dart
│   │   └── content_version.dart
│   └── repos/               # Repository layer
│       ├── auth_repository.dart
│       ├── auth_repository_impl.dart
│       ├── content_repository.dart
│       ├── content_repository_impl.dart
│       ├── assessment_repository.dart
│       ├── assessment_repository_impl.dart
│       ├── progress_repository.dart
│       └── progress_repository_impl.dart
├── features/                # Feature modules
│   ├── auth/                # Authentication
│   │   ├── login_screen.dart
│   │   └── role_select_screen.dart
│   ├── student/             # Student features
│   │   ├── dashboard/
│   │   ├── lesson_reader/
│   │   ├── quiz/
│   │   └── progress/
│   └── teacher/             # Teacher features
│       └── panel_stub/
└── services/                # Service layer
    └── sync/                # Sync services (Phase 2)
        ├── content_sync_service.dart
        └── progress_sync_service.dart
└── features/                # Feature modules
    ├── auth/                # Authentication
    │   ├── login_screen.dart
    │   └── role_select_screen.dart
    ├── student/             # Student features
    │   ├── dashboard/
    │   ├── lesson_reader/
    │   ├── quiz/
    │   └── progress/
    └── teacher/             # Teacher features (Phase 2)
        └── panel_stub/
            ├── teacher_panel_screen.dart
            └── widgets/
                ├── lesson_editor.dart
                ├── quiz_editor.dart
                └── student_progress_widget.dart
```

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd hopes
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### First Launch

On first launch, the app will:
1. Create the local SQLite database
2. Import seed data (Grade 7 Science curriculum)
3. Show the login screen

### Demo Mode

You can quickly test the app by:
1. Clicking "Skip Sign-in (Demo)" on the login screen
2. Selecting "Student" role
3. Taking the pre-assessment to determine your learning track
4. Exploring lessons and taking quizzes

### Testing Phase 2 Features

#### Teacher Panel Testing
1. **Login as Teacher**: Use the role selection to switch to teacher mode
2. **Create Content**:
   - Navigate to the Lessons tab
   - Use the floating action button to create new lessons
   - Edit existing lessons with the markdown editor
   - Create quizzes with multiple choice questions
3. **Monitor Students**: 
   - Go to the Progress tab to view class analytics
   - Check individual student progress and badges

#### Student Gamification Testing
1. **Login as Student**: Switch to student mode
2. **Earn Points**: Complete quizzes to earn points
3. **Unlock Badges**: 
   - Complete your first quiz for the Starter Badge
   - Score 85% or higher 3 times for the Achiever Badge
   - Maintain a 7-day learning streak for the Consistency Badge
4. **View Progress**: Check the "My Progress" section on the dashboard

#### Sync Simulation
The app simulates online/offline sync functionality. Changes made offline are queued and synced when the app detects an online connection.

## Data Model

### Core Entities

- **User**: Students and teachers with role-based access
- **Subject**: Academic subjects (e.g., Science 7)
- **Module**: Subject modules (e.g., Biology Basics)
- **Lesson**: Individual lessons with markdown content
- **Assessment**: Quizzes and pre-assessments with questions
- **Attempt**: Student quiz attempts with scores
- **Progress**: Lesson progress tracking (locked/in-progress/mastered)

### Phase 2 Entities

- **Classroom**: Groups students by teacher and subject
- **Points**: Tracks user points for gamification
- **Badge**: Defines achievement badges with rules
- **UserBadge**: Links users to earned badges
- **SyncQueue**: Manages offline changes for synchronization

### Seed Content

The app includes a complete Grade 7 Science curriculum:
- **Subject**: Science 7
- **Module**: Biology Basics
- **Lessons**: 
  - Cells: The Building Blocks of Life
  - Classification of Living Things
  - Ecosystems and Interactions
- **Assessments**: 1 pre-assessment + 3 lesson quizzes (5 questions each)

## Architecture

### State Management
- **Riverpod**: Dependency injection and state management
- **AsyncValue**: Loading, success, and error states
- **StateNotifier**: Complex state logic (AuthNotifier)

### Database
- **Drift**: Type-safe SQLite ORM
- **Migrations**: Schema versioning support
- **Seed Data**: Automatic content import on first run

### Routing
- **Go Router**: Declarative routing with deep linking
- **Route Guards**: Authentication-based navigation
- **Nested Routes**: Feature-based organization

## Testing

### Running Tests
```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widget_test.dart

# Integration tests (when added)
flutter test integration_test/
```

### Test Coverage
- Repository layer with mock database
- Quiz engine scoring logic
- State management with Riverpod
- Widget testing for key screens

## Adding New Content

### Adding Lessons to Seed Data

1. **Update the seed JSON file** (`assets/seed/grade7_science.json`):
   ```json
   {
     "lessons": [
       {
         "id": "new_lesson_id",
         "moduleId": "biology_basics",
         "title": "New Lesson Title",
         "bodyMarkdown": "# Lesson Content\n\nYour markdown content here...",
         "estMins": 15
       }
     ]
   }
   ```

2. **Add corresponding quiz**:
   ```json
   {
     "assessments": [
       {
         "id": "new_lesson_quiz",
         "lessonId": "new_lesson_id",
         "type": "quiz",
         "items": [
           {
             "id": "q1",
             "text": "Question text?",
             "choices": ["A", "B", "C", "D"],
             "correctIndex": 0
           }
         ]
       }
     ]
   }
   ```

3. **Regenerate seed data**:
   ```bash
   flutter packages pub run build_runner build
   ```

## Phase 2 Roadmap

### Backend Integration
- [ ] Real authentication with JWT tokens
- [ ] Content synchronization API
- [ ] Progress backup and restore
- [ ] User management system

### Teacher Features
- [ ] Content upload interface
- [ ] Student progress analytics
- [ ] Assessment creation tools
- [ ] Class management

### Advanced Features
- [ ] Gamification (badges, achievements)
- [ ] Adaptive learning algorithms
- [ ] Multi-subject support
- [ ] Offline content updates
- [ ] Push notifications

### Performance & UX
- [ ] Content caching optimization
- [ ] Image and media support
- [ ] Accessibility improvements
- [ ] Internationalization (i18n)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run `flutter analyze` and `flutter test`
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or issues:
1. Check the existing issues
2. Create a new issue with detailed information
3. Include device info and error logs

---

**HOPES** - Empowering Grade 7 students with accessible, offline-first learning experiences.
# hopes
