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

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(p.join(directory.path, 'inspection_app.sqlite'));

    return NativeDatabase(file);
  });
}
