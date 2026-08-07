import 'package:drift/drift.dart';

class WorkOrders extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get address => text()();
  TextColumn get priority => text()();
  TextColumn get status => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get notes => text()();
}
