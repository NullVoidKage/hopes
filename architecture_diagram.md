# Hopes E-Learning Platform - Architecture Documentation

## High-Level Architecture Diagram

```mermaid
graph TB
    subgraph "Client Layer"
        A[Flutter App]
        A1[Student Dashboard]
        A2[Teacher Panel]
        A3[Auth Screens]
        A4[Content Management]
        A5[Assessment System]
    end
    
    subgraph "Service Layer"
        B[Auth Service]
        C[Lesson Service]
        D[Assessment Service]
        E[Student Service]
        F[Progress Service]
        G[Achievements Service]
        H[Offline Service]
        I[Connectivity Service]
    end
    
    subgraph "Data Layer"
        J[Firebase Auth]
        K[Cloud Firestore]
        L[Firebase Realtime DB]
        M[Firebase Storage]
        N[Shared Preferences]
    end
    
    subgraph "External Services"
        O[Google Sign-In]
        P[File Picker]
    end
    
    A --> B
    A --> C
    A --> D
    A --> E
    A --> F
    A --> G
    A --> H
    A --> I
    
    B --> J
    B --> O
    C --> K
    C --> L
    D --> L
    E --> K
    F --> L
    G --> L
    H --> N
    I --> N
    
    C --> M
    A4 --> P
```

## User Flow Diagram

```mermaid
flowchart TD
    Start([App Launch]) --> Auth{User Authenticated?}
    
    Auth -->|No| SignIn[Sign In Screen]
    Auth -->|Yes| Profile{Profile Exists?}
    
    SignIn --> GoogleSignIn[Google Sign In]
    SignIn --> EmailSignIn[Email/Password Sign In]
    SignIn --> SignUp[Sign Up]
    
    GoogleSignIn --> RoleSelection[Role Selection]
    EmailSignIn --> RoleSelection
    SignUp --> RoleSelection
    
    RoleSelection --> StudentRole[Student Role]
    RoleSelection --> TeacherRole[Teacher Role]
    
    StudentRole --> StudentDashboard[Student Dashboard]
    TeacherRole --> TeacherPanel[Teacher Panel]
    
    StudentDashboard --> TakeAssessment[Take Assessment]
    StudentDashboard --> ViewLessons[View Lessons]
    StudentDashboard --> ViewProgress[View Progress]
    StudentDashboard --> ViewBadges[View Badges]
    StudentDashboard --> Leaderboard[Leaderboard]
    
    TeacherPanel --> UploadLessons[Upload Lessons]
    TeacherPanel --> CreateAssessments[Create Assessments]
    TeacherPanel --> ManageStudents[Manage Students]
    TeacherPanel --> MonitorProgress[Monitor Progress]
    TeacherPanel --> LearningPaths[Learning Paths]
    TeacherPanel --> Feedback[Feedback Management]
    
    TakeAssessment --> AssessmentTaker[Assessment Taker Screen]
    ViewLessons --> LessonViewer[Lesson Viewer Screen]
    UploadLessons --> LessonUpload[Lesson Upload Screen]
    CreateAssessments --> AssessmentCreation[Assessment Creation Screen]
```

## Data Flow Diagram

```mermaid
flowchart LR
    subgraph "UI Layer"
        UI[User Interface]
    end
    
    subgraph "Service Layer"
        AuthSvc[Auth Service]
        LessonSvc[Lesson Service]
        AssessmentSvc[Assessment Service]
        OfflineSvc[Offline Service]
        ConnSvc[Connectivity Service]
    end
    
    subgraph "Data Sources"
        Firestore[(Cloud Firestore)]
        RealtimeDB[(Realtime Database)]
        Storage[(Firebase Storage)]
        LocalStorage[(Shared Preferences)]
    end
    
    subgraph "External APIs"
        Google[Google Sign-In]
        FilePicker[File Picker]
    end
    
    UI --> AuthSvc
    UI --> LessonSvc
    UI --> AssessmentSvc
    
    AuthSvc --> Firestore
    AuthSvc --> Google
    
    LessonSvc --> Firestore
    LessonSvc --> RealtimeDB
    LessonSvc --> Storage
    
    AssessmentSvc --> RealtimeDB
    
    OfflineSvc --> LocalStorage
    ConnSvc --> LocalStorage
    
    UI --> FilePicker
    FilePicker --> Storage
```

## Component Architecture

```mermaid
graph TB
    subgraph "Presentation Layer"
        A[Auth Wrapper]
        B[Sign In Screen]
        C[Role Selection Screen]
        D[Student Dashboard]
        E[Teacher Panel]
        F[Lesson Upload Screen]
        G[Assessment Creation Screen]
        H[Student Management Screen]
        I[Progress Monitoring Screen]
    end
    
    subgraph "Business Logic Layer"
        J[Auth Service]
        K[Lesson Service]
        L[Assessment Service]
        M[Student Service]
        N[Progress Service]
        O[Achievements Service]
        P[Offline Service]
        Q[Connectivity Service]
    end
    
    subgraph "Data Models"
        R[User Model]
        S[Lesson Model]
        T[Assessment Model]
        U[Student Model]
        V[Progress Model]
        W[Achievement Model]
    end
    
    subgraph "External Dependencies"
        X[Firebase Auth]
        Y[Cloud Firestore]
        Z[Realtime Database]
        AA[Firebase Storage]
        BB[Google Sign-In]
        CC[File Picker]
        DD[Shared Preferences]
    end
    
    A --> J
    B --> J
    C --> J
    D --> K
    D --> L
    D --> N
    D --> O
    E --> K
    E --> L
    E --> M
    E --> N
    F --> K
    G --> L
    H --> M
    I --> N
    
    J --> R
    K --> S
    L --> T
    M --> U
    N --> V
    O --> W
    
    J --> X
    J --> BB
    K --> Y
    K --> Z
    K --> AA
    L --> Z
    M --> Y
    N --> Z
    O --> Z
    P --> DD
    Q --> DD
    F --> CC
```

## State Management Flow

```mermaid
stateDiagram-v2
    [*] --> AppInitialization
    
    AppInitialization --> AuthCheck
    AuthCheck --> NotAuthenticated : No User
    AuthCheck --> ProfileCheck : User Found
    
    NotAuthenticated --> SignInScreen
    SignInScreen --> GoogleSignIn : Google Auth
    SignInScreen --> EmailSignIn : Email Auth
    SignInScreen --> SignUp : New User
    
    GoogleSignIn --> RoleSelection
    EmailSignIn --> RoleSelection
    SignUp --> RoleSelection
    
    RoleSelection --> StudentDashboard : Student Role
    RoleSelection --> TeacherPanel : Teacher Role
    
    ProfileCheck --> StudentDashboard : Student Profile
    ProfileCheck --> TeacherPanel : Teacher Profile
    ProfileCheck --> RoleSelection : No Profile
    
    StudentDashboard --> TakeAssessment
    StudentDashboard --> ViewLessons
    StudentDashboard --> ViewProgress
    StudentDashboard --> ViewBadges
    
    TeacherPanel --> UploadLessons
    TeacherPanel --> CreateAssessments
    TeacherPanel --> ManageStudents
    TeacherPanel --> MonitorProgress
    
    TakeAssessment --> AssessmentComplete
    ViewLessons --> LessonComplete
    UploadLessons --> LessonUploaded
    CreateAssessments --> AssessmentCreated
    
    AssessmentComplete --> StudentDashboard
    LessonComplete --> StudentDashboard
    LessonUploaded --> TeacherPanel
    AssessmentCreated --> TeacherPanel
```

## Database Schema

```mermaid
erDiagram
    USER ||--o{ LESSON : creates
    USER ||--o{ ASSESSMENT : creates
    USER ||--o{ STUDENT_PROGRESS : has
    USER ||--o{ ACHIEVEMENT : earns
    
    USER {
        string uid PK
        string email
        string displayName
        string photoURL
        enum role
        string grade
        array subjects
        timestamp createdAt
        timestamp lastLogin
    }
    
    LESSON {
        string id PK
        string title
        string subject
        string content
        string teacherId FK
        string teacherName
        timestamp createdAt
        timestamp updatedAt
        boolean isPublished
        array tags
        string description
        string fileUrl
    }
    
    ASSESSMENT {
        string id PK
        string title
        string description
        string subject
        string teacherId FK
        string teacherName
        timestamp createdAt
        timestamp updatedAt
        boolean isPublished
        array tags
        int timeLimit
        int totalPoints
        array questions
        timestamp dueDate
    }
    
    ASSESSMENT_QUESTION {
        string id PK
        string question
        enum type
        array options
        array correctAnswers
        string correctAnswer
        int points
        string explanation
        boolean showCorrectAnswer
    }
    
    ASSESSMENT_SUBMISSION {
        string id PK
        string assessmentId FK
        string studentId FK
        string teacherId FK
        string studentName
        string studentEmail
        string studentGrade
        string assessmentTitle
        string assessmentSubject
        int totalQuestions
        int maxPossibleScore
        map detailedAnswers
        int score
        double accuracy
        int correctAnswers
        int incorrectAnswers
        int unansweredQuestions
        timestamp submittedAt
        timestamp startedAt
        int timeSpent
        double averageTimePerQuestion
        boolean isGraded
        boolean isAutoGraded
    }
    
    STUDENT_PROGRESS {
        string id PK
        string studentId FK
        string studentName
        string studentEmail
        string subject
        int lessonsCompleted
        int totalLessons
        int assessmentsTaken
        int totalAssessments
        double averageScore
        double completionRate
        timestamp lastActivity
        map lessonProgress
        map assessmentProgress
        map metadata
    }
    
    ACHIEVEMENT {
        string id PK
        string title
        string description
        string category
        int points
        string iconName
        string colorHex
        map criteria
        boolean isActive
        timestamp createdAt
        timestamp updatedAt
    }
    
    STUDENT_ACHIEVEMENT {
        string id PK
        string studentId FK
        string studentName
        string achievementId FK
        string achievementTitle
        string achievementDescription
        int points
        timestamp unlockedAt
        map metadata
    }
    
    LEADERBOARD_ENTRY {
        string studentId PK
        string studentName
        string studentEmail
        int totalPoints
        int achievementsCount
        int rank
        timestamp lastActivity
        map stats
    }
```

## Offline Architecture

```mermaid
graph TB
    subgraph "Online Mode"
        A[User Action] --> B[Connectivity Check]
        B -->|Online| C[Service Layer]
        C --> D[Firebase Services]
        D --> E[Data Response]
        E --> F[Update UI]
        E --> G[Cache Data]
    end
    
    subgraph "Offline Mode"
        A --> B
        B -->|Offline| H[Offline Service]
        H --> I[Local Storage]
        I --> J[Cached Data]
        J --> F
        J --> K[Queue for Sync]
    end
    
    subgraph "Sync Process"
        L[Connection Restored] --> M[Sync Service]
        M --> N[Process Queued Actions]
        N --> O[Update Firebase]
        O --> P[Clear Queue]
    end
    
    K --> L
```

## Security Architecture

```mermaid
graph TB
    subgraph "Authentication"
        A[User Login] --> B[Firebase Auth]
        B --> C[Google OAuth]
        B --> D[Email/Password]
        C --> E[JWT Token]
        D --> E
    end
    
    subgraph "Authorization"
        E --> F[Role Check]
        F --> G[Student Access]
        F --> H[Teacher Access]
        G --> I[Student Features]
        H --> J[Teacher Features]
    end
    
    subgraph "Data Security"
        K[Firestore Rules] --> L[User Data Access]
        M[Realtime DB Rules] --> N[Assessment Data Access]
        O[Storage Rules] --> P[File Access Control]
    end
    
    I --> K
    J --> K
    I --> M
    J --> M
    I --> O
    J --> O
```

## Performance Optimization

```mermaid
graph TB
    subgraph "Caching Strategy"
        A[Data Request] --> B{Cache Available?}
        B -->|Yes| C[Return Cached Data]
        B -->|No| D[Fetch from Firebase]
        D --> E[Cache Data]
        E --> F[Return Data]
    end
    
    subgraph "Lazy Loading"
        G[Screen Load] --> H[Load Critical Data]
        H --> I[Load Secondary Data]
        I --> J[Load Optional Data]
    end
    
    subgraph "Image Optimization"
        K[Image Request] --> L[Check Cache]
        L -->|Hit| M[Return Cached Image]
        L -->|Miss| N[Download & Resize]
        N --> O[Cache Image]
        O --> M
    end
```

## Error Handling Flow

```mermaid
flowchart TD
    A[User Action] --> B[Service Call]
    B --> C{Success?}
    C -->|Yes| D[Update UI]
    C -->|No| E[Error Type?]
    
    E --> F[Network Error]
    E --> G[Auth Error]
    E --> H[Validation Error]
    E --> I[Server Error]
    
    F --> J[Show Offline Mode]
    F --> K[Use Cached Data]
    
    G --> L[Redirect to Login]
    
    H --> M[Show Validation Message]
    
    I --> N[Show Error Message]
    I --> O[Retry Option]
    
    J --> P[Queue for Sync]
    K --> D
    L --> Q[Sign In Screen]
    M --> R[User Input]
    N --> S[User Action]
    O --> B
    P --> T[Background Sync]
```

## Deployment Architecture

```mermaid
graph TB
    subgraph "Development"
        A[Flutter App] --> B[Firebase Emulator]
        B --> C[Local Testing]
    end
    
    subgraph "Staging"
        D[Flutter App] --> E[Firebase Staging]
        E --> F[QA Testing]
    end
    
    subgraph "Production"
        G[Flutter App] --> H[Firebase Production]
        H --> I[Live Users]
    end
    
    subgraph "CI/CD Pipeline"
        J[Code Push] --> K[Build]
        K --> L[Test]
        L --> M[Deploy to Staging]
        M --> N[Manual Approval]
        N --> O[Deploy to Production]
    end
    
    C --> M
    F --> N
```

## Monitoring & Analytics

```mermaid
graph TB
    subgraph "User Analytics"
        A[User Actions] --> B[Firebase Analytics]
        B --> C[Usage Patterns]
        C --> D[Performance Metrics]
    end
    
    subgraph "Error Monitoring"
        E[App Errors] --> F[Firebase Crashlytics]
        F --> G[Error Reports]
        G --> H[Debug Information]
    end
    
    subgraph "Performance Monitoring"
        I[App Performance] --> J[Firebase Performance]
        J --> K[Load Times]
        K --> L[Network Requests]
    end
    
    subgraph "Custom Metrics"
        M[Learning Progress] --> N[Custom Analytics]
        N --> O[Student Performance]
        O --> P[Teacher Insights]
    end
```

## Key Features Architecture

### 1. Authentication System
- **Firebase Authentication** with Google OAuth and Email/Password
- **Role-based access control** (Student/Teacher)
- **Profile management** with grade and subject assignment
- **Offline authentication state** persistence

### 2. Content Management
- **Lesson creation and management** with file upload support
- **Assessment creation** with multiple question types
- **Learning path design** for structured learning
- **Content categorization** by subjects and tags

### 3. Student Learning Experience
- **Interactive lesson viewer** with file preview
- **Assessment taking system** with timer and progress tracking
- **Progress monitoring** with detailed analytics
- **Achievement system** with badges and leaderboard
- **Offline content access** with sync capabilities

### 4. Teacher Management Tools
- **Student management** with enrollment and progress tracking
- **Content creation tools** for lessons and assessments
- **Analytics dashboard** with performance insights
- **Feedback system** for student engagement
- **Learning path assignment** and monitoring

### 5. Offline Capabilities
- **Local data caching** using SharedPreferences
- **Offline content access** for lessons and assessments
- **Sync queue management** for offline actions
- **Connectivity monitoring** with automatic fallback

### 6. Data Architecture
- **Cloud Firestore** for user profiles and lesson metadata
- **Firebase Realtime Database** for assessments and progress
- **Firebase Storage** for file uploads and media
- **SharedPreferences** for local caching and settings

This architecture provides a robust, scalable, and offline-capable e-learning platform specifically designed for Grade 7 students and teachers in the Philippines.
