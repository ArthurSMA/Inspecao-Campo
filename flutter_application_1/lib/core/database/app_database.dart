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
  int get schemaVersion => 3;

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
      }
      if (from < 3) {
        await customStatement('''
          CREATE TABLE inspections_v3 (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            client_id TEXT NOT NULL UNIQUE,
            work_order_id TEXT NOT NULL,
            observation TEXT NOT NULL,
            condition TEXT NULL,
            photo_path TEXT NULL,
            latitude REAL NULL,
            longitude REAL NULL,
            captured_at INTEGER NOT NULL,
            status TEXT NOT NULL CHECK (status IN ('draft', 'pending', 'synced', 'failed')),
            server_id TEXT NULL,
            error_message TEXT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await customStatement('''
          INSERT INTO inspections_v3 (
            id, client_id, work_order_id, observation, condition, photo_path,
            latitude, longitude, captured_at, status, server_id, error_message,
            created_at, updated_at
          )
          SELECT
            id,
            lower(hex(randomblob(4))) || '-' ||
              lower(hex(randomblob(2))) || '-4' ||
              substr(lower(hex(randomblob(2))), 2) || '-' ||
              substr('89ab', abs(random()) % 4 + 1, 1) ||
              substr(lower(hex(randomblob(2))), 2) || '-' ||
              lower(hex(randomblob(6))),
            work_order_id,
            comment,
            NULL,
            photo_path,
            latitude,
            longitude,
            created_at,
            CASE
              WHEN status IN ('draft', 'pending', 'synced', 'failed') THEN status
              ELSE 'draft'
            END,
            NULL,
            NULL,
            created_at,
            updated_at
          FROM inspections
        ''');
        await customStatement('DROP TABLE inspections');
        await customStatement(
          'ALTER TABLE inspections_v3 RENAME TO inspections',
        );
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
