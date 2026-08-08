import 'package:drift/drift.dart';

class Inspections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text().unique()();
  TextColumn get workOrderId => text()();
  TextColumn get observation => text()();
  TextColumn get condition => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get status => text().customConstraint(
    "NOT NULL CHECK (status IN ('draft', 'pending', 'synced', 'failed'))",
  )();
  TextColumn get serverId => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
