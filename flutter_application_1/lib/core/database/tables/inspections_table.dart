import 'package:drift/drift.dart';

class Inspections extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get workOrderId => text()();
  TextColumn get comment => text()();
  TextColumn get status => text()();

  TextColumn get photoPath => text().nullable()();

  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
