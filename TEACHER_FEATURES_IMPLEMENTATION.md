# Teacher Features Implementation Plan

## Overview
This document outlines the implementation plan for all 15 teacher features requested.

## Features Status

### ✅ Already Implemented
- **Feature 12**: Check if student already took assessment (already prevents retakes)

### 🔄 In Progress
- **Feature 1**: Subject restrictions (teachers can only upload for assigned subjects)

### ⏳ Pending Implementation
- **Feature 2**: Lesson tag validation (video tag requires video file/link)
- **Feature 3**: Remove beginner/intermediate/advanced tags
- **Feature 4**: Video upload/link capability for lessons
- **Feature 5**: Individual lesson tracking per student per subject
- **Feature 6**: Google Classroom-style class code system for sections
- **Feature 7**: Move "Add Questions" button to bottom
- **Feature 8**: Drag and drop question arrangement
- **Feature 9**: Manual point assignment for essay questions
- **Feature 10**: Exclude essay questions from auto-grading
- **Feature 11**: Individual ratings (per student, per section, per subject, overall)
- **Feature 13**: Dashboard filters (per student, per section, per subject, overall)
- **Feature 14**: Class creation by teacher for sections and subjects
- **Feature 15**: Prevent assessment taking for sections under moderation

## Implementation Priority

### Phase 1: Critical Features (High Priority)
1. ✅ Subject restrictions enforcement
2. Remove beginner/intermediate/advanced tags
3. Video tag validation (video tag requires video)
4. Move "Add Questions" button to bottom
5. Manual grading for essay questions

### Phase 2: Assessment Enhancements
6. Drag and drop question arrangement
7. Exclude essay from auto-grading
8. Individual lesson tracking per student

### Phase 3: Class/Section Management
9. Google Classroom-style class code system
10. Class creation by teacher
11. Section moderation blocking

### Phase 4: Dashboard & Analytics
12. Individual ratings system
13. Dashboard filters (per student/section/subject/overall)

## Technical Implementation Notes

### 1. Subject Restrictions
- **Location**: `lesson_upload_screen.dart`, `assessment_creation_screen.dart`
- **Change**: Filter subjects dropdown to only show teacher's assigned subjects
- **Validation**: Add server-side validation in services

### 2. Tag System Updates
- **Remove**: Beginner, Intermediate, Advanced from available tags
- **Validate**: If "Video" tag selected, require video file/link
- **Location**: `lesson_upload_screen.dart` line 41-46

### 3. Video Upload/Link
- **Add**: Video file upload support
- **Add**: Video URL link field option
- **Location**: `lesson_upload_screen.dart` file upload section

### 4. Assessment UI Improvements
- **Move**: "Add Questions" button to bottom of questions list
- **Add**: Drag and drop reordering using `reorderable_list_view`
- **Location**: `assessment_creation_screen.dart`

### 5. Essay Question Handling
- **Manual Grading**: Flag essay questions for manual review
- **Auto-exclude**: Skip essay questions in auto-grading
- **Points**: Allow manual point assignment in grading screen
- **Location**: `assessment_creation_screen.dart`, `assessment_grading_screen.dart`

### 6. Class/Section Management
- **New Model**: `ClassModel` with section, subject, teacher, classCode
- **New Service**: `ClassService` for class management
- **New Screen**: `class_creation_screen.dart`, `class_management_screen.dart`
- **Code System**: Generate unique 6-character class codes

### 7. Dashboard Filters
- **Add**: Filter dropdowns for student, section, subject
- **Add**: "Overall" view option
- **Update**: `teacher_panel.dart` dashboard queries

### 8. Individual Ratings
- **Model**: Rating per student-section-subject combination
- **Service**: `RatingService` for rating calculations
- **Display**: Per student, per section, per subject views

### 9. Section Moderation
- **Add**: `isModerated` flag to sections/classes
- **Check**: Block assessment access if section is moderated
- **Location**: `student_assessment_taker_screen.dart`

## Database Schema Changes

### New Collections/Tables Needed:
1. **classes** - Class information (section, subject, teacher, code)
2. **class_enrollments** - Student enrollments in classes
3. **student_ratings** - Individual ratings per student-section-subject
4. **lesson_progress** - Individual lesson progress tracking

### Model Updates:
- `Lesson`: Add `videoUrl` field
- `Assessment`: Add `classId`, `sectionId` fields
- `UserModel`: Add `classes` array for students

## Next Steps
1. Implement Phase 1 features (critical)
2. Test subject restrictions and tag validation
3. Implement Phase 2 features (assessment enhancements)
4. Implement Phase 3 features (class management)
5. Implement Phase 4 features (dashboard & analytics)
6. Comprehensive testing
7. Documentation updates

