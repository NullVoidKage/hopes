# Firebase Rules Update for Teacher Features

## ✅ Yes, Firebase Rules Need to be Deployed

The new teacher features require updates to Firebase Security Rules:

## Updates Required

### 1. Realtime Database Rules ✅ Updated
**File**: `firebase_realtime_rules.json`

**Changes Made**:
- ✅ Added `schoolYear` to lessons index
- ✅ Added `classes` collection rules for class management
- ✅ Added `class_enrollments` collection rules
- ✅ Added `lesson_progress` collection rules for individual tracking
- ✅ Added `student_ratings` collection rules

**Action Required**:
```bash
firebase deploy --only database
```

### 2. Firestore Rules ✅ Updated
**File**: `firestore.rules`

**Changes Made**:
- ✅ Added `classes` collection rules
- ✅ Added `class_enrollments` collection rules
- ✅ Added `lesson_progress` collection rules
- ✅ Added `student_ratings` collection rules

**Action Required**:
```bash
firebase deploy --only firestore:rules
```

### 3. Storage Rules ✅ Updated
**File**: `storage.rules`

**Changes Made**:
- ✅ Added comment for video file support in lesson_files
- ✅ Added `lesson_videos` path for video files (alternative path)

**Action Required**:
```bash
firebase deploy --only storage
```

### 4. Lesson Service Update ✅ Fixed
**File**: `lib/services/lesson_service_realtime.dart`

**Changes Made**:
- ✅ Added `videoUrl` to lesson creation
- ✅ Added `schoolYear` to lesson creation
- ✅ Updated caching to include new fields

**Note**: This is a code update, not a rules update

## Deploy All Rules

### Deploy Everything at Once:
```bash
firebase deploy --only storage,firestore:rules,database
```

### Or Deploy Individually:

**Storage Rules** (for video files):
```bash
firebase deploy --only storage
```

**Firestore Rules** (for new collections):
```bash
firebase deploy --only firestore:rules
```

**Realtime Database Rules** (for new collections and indexes):
```bash
firebase deploy --only database
```

## New Collections Added

### Realtime Database:
1. **classes** - Class information with section, subject, teacher, class code
2. **class_enrollments** - Student enrollments in classes
3. **lesson_progress** - Individual lesson progress per student
4. **student_ratings** - Individual ratings per student/section/subject

### Firestore:
1. **classes** - Class information (for Firestore backup)
2. **class_enrollments** - Student enrollments
3. **lesson_progress** - Individual lesson tracking
4. **student_ratings** - Individual ratings

## Updated Fields

### Lessons:
- ✅ `videoUrl` - Optional video URL or link
- ✅ `schoolYear` - School year field

### Indexes Added:
- `lessons.schoolYear` - For filtering by school year
- `classes.teacherId`, `classes.subject`, `classes.section`, `classes.classCode`, `classes.schoolYear`
- `class_enrollments.classId`, `class_enrollments.studentId`, `class_enrollments.teacherId`
- `lesson_progress.studentId`, `lesson_progress.lessonId`, `lesson_progress.subject`, `lesson_progress.teacherId`
- `student_ratings.studentId`, `student_ratings.sectionId`, `student_ratings.subjectId`, `student_ratings.teacherId`

## Security Rules Summary

### Classes:
- Teachers can create/read/write their own classes
- Students can read classes they're enrolled in
- Class codes are managed by teachers

### Class Enrollments:
- Teachers can create/manage enrollments
- Students can read their own enrollments
- Enrollment requires teacher approval

### Lesson Progress:
- Students can create/update their own progress
- Teachers can read progress for their students
- Individual tracking per student/lesson/subject

### Student Ratings:
- Teachers can create/update ratings
- Students can read their own ratings
- Ratings organized by student/section/subject

## Important Notes

1. **videoUrl Field**: Added to lessons but optional - existing lessons will work fine
2. **schoolYear Field**: Added to lessons - supports filtering by school year
3. **Class System**: Rules are ready but classes collection won't be used until services are implemented
4. **Storage for Videos**: Video files can be uploaded to `lesson_files` or `lesson_videos` paths

## Verification

After deploying, verify:
1. ✅ Lessons can be created with videoUrl and schoolYear
2. ✅ Video files can be uploaded to storage
3. ✅ Classes can be created (when service is implemented)
4. ✅ Lesson progress can be tracked (when service is implemented)
5. ✅ Student ratings can be created (when service is implemented)

## Next Steps

1. Deploy all Firebase rules
2. Test lesson creation with videoUrl
3. Test video file upload
4. Implement ClassService when ready
5. Implement lesson progress tracking
6. Implement ratings system

