import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/users_table.dart';
import 'tables/work_orders_table.dart';
import 'tables/inspections_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Users, WorkOrders, Inspections])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await customStatement(
          'DELETE FROM work_orders '
          'WHERE rowid NOT IN ('
          'SELECT MAX(rowid) FROM work_orders GROUP BY id'
          ')',
        );
        await migrator.alterTable(TableMigration(workOrders));
        await migrator.alterTable(TableMigration(inspections));
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(p.join(directory.path, 'inspection_app.sqlite'));

    return NativeDatabase(file);
  });
}
