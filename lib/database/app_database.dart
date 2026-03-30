import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// =======================
// TABLE USERS
// =======================
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get email => text().unique()();

  TextColumn get phoneNumber => text().unique()();

  TextColumn get name => text()();

  TextColumn get passwordHash => text()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// =======================
// TABLE DOCUMENTS
// =======================
class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get userId => integer().references(Users, #id)();

  TextColumn get title => text()();

  TextColumn get originalText => text()();

  TextColumn get filePath => text().nullable()();

  TextColumn get language => text().withDefault(const Constant('fr'))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// =======================
// TABLE SUMMARIES
// =======================
class Summaries extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get documentId =>
      integer().references(Documents, #id)();

  IntColumn get userId =>
      integer().references(Users, #id)();

  TextColumn get summaryText => text()();

  IntColumn get summaryLevel => integer()();

  TextColumn get aiModel => text()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// =======================
// TABLE FAVORITES
// =======================
class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get userId =>
      integer().references(Users, #id)();

  IntColumn get summaryId =>
      integer().references(Summaries, #id)();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// =======================
// DATABASE
// =======================
@DriftDatabase(
  tables: [Users, Documents, Summaries, Favorites],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  // =======================
  // USERS
  // =======================
  Future<int> createUser(UsersCompanion user) =>
      into(users).insert(user);

  Future<User?> getUserByEmail(String email) {
    return (select(users)..where((u) => u.email.equals(email)))
        .getSingleOrNull();
  }

  Future<User?> getUserByPhone(String phone) {
    return (select(users)..where((u) => u.phoneNumber.equals(phone)))
        .getSingleOrNull();
  }

  // =======================
  // DOCUMENTS
  // =======================
  Future<int> createDocument(DocumentsCompanion doc) =>
      into(documents).insert(doc);

  Stream<List<Document>> watchUserDocuments(int userId) {
    return (select(documents)
      ..where((d) => d.userId.equals(userId)))
        .watch();
  }

  // =======================
  // SUMMARIES
  // =======================
  Future<int> createSummary(SummariesCompanion sum) =>
      into(summaries).insert(sum);

  Stream<List<Summary>> watchSummaries(int docId) {
    return (select(summaries)
      ..where((s) => s.documentId.equals(docId)))
        .watch();
  }
}

// =======================
// OPEN DATABASE (ANDROID SAFE)
// =======================
QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'resuma.db',
  );
}