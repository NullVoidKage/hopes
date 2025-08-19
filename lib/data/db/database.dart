import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get role => textEnum<UserRole>()();
  TextColumn get section => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get gradeLevel => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Modules extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get title => text()();
  TextColumn get version => text()();
  BoolColumn get isPublished => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

class Lessons extends Table {
  TextColumn get id => text()();
  TextColumn get moduleId => text().references(Modules, #id)();
  TextColumn get title => text()();
  TextColumn get bodyMarkdown => text()();
  IntColumn get estMins => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Assessments extends Table {
  TextColumn get id => text()();
  TextColumn get lessonId => text().references(Lessons, #id).nullable()();
  TextColumn get type => textEnum<AssessmentType>()();
  TextColumn get itemsJson => text()(); // JSON string of questions

  @override
  Set<Column> get primaryKey => {id};
}

class Attempts extends Table {
  TextColumn get id => text()();
  TextColumn get assessmentId => text().references(Assessments, #id)();
  TextColumn get userId => text().references(Users, #id)();
  RealColumn get score => real()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime()();
  TextColumn get answersJson => text()(); // JSON string of answers

  @override
  Set<Column> get primaryKey => {id};
}

class Progress extends Table {
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get lessonId => text().references(Lessons, #id)();
  TextColumn get status => textEnum<ProgressStatus>()();
  RealColumn get lastScore => real().nullable()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId, lessonId};
}

class Badges extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get ruleJson => text()(); // JSON string of rules

  @override
  Set<Column> get primaryKey => {id};
}

class UserBadges extends Table {
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get badgeId => text().references(Badges, #id)();
  DateTimeColumn get awardedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId, badgeId};
}

class ContentVersions extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get version => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Classrooms extends Table {
  TextColumn get id => text()();
  TextColumn get teacherId => text().references(Users, #id)();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Points extends Table {
  TextColumn get userId => text().references(Users, #id)();
  IntColumn get totalPoints => integer()();

  @override
  Set<Column> get primaryKey => {userId};
}

class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get entityTable => text()();
  TextColumn get operation => text()(); // 'create', 'update', 'delete'
  TextColumn get recordId => text()();
  TextColumn get dataJson => text()(); // JSON string of the data
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

enum UserRole { student, teacher }
enum AssessmentType { pre, quiz }
enum ProgressStatus { locked, inProgress, mastered }

@DriftDatabase(tables: [
  Users,
  Subjects,
  Modules,
  Lessons,
  Assessments,
  Attempts,
  Progress,
  Badges,
  UserBadges,
  ContentVersions,
  Classrooms,
  Points,
  SyncQueue,
])
class HopesDatabase extends _$HopesDatabase {
  HopesDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations will go here
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'hopes.db'));
    return NativeDatabase.createInBackground(file);
  });
} 