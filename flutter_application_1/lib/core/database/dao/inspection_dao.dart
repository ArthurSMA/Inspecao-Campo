import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/inspections_table.dart';

part 'inspection_dao.g.dart';

@DriftAccessor(tables: [Inspections])
class InspectionDao extends DatabaseAccessor<AppDatabase>
    with _$InspectionDaoMixin {
  InspectionDao(super.db);

  Future<void> saveInspection(InspectionsCompanion inspection) async {
    await into(inspections).insertOnConflictUpdate(inspection);
  }

  Future<List<Inspection>> getAllInspections() {
    return select(inspections).get();
  }

  Future<List<Inspection>> getPendingInspections() {
    return (select(
      inspections,
    )..where((table) => table.synced.equals(false))).get();
  }

  Future<void> markAsSynced(int id) async {
    await (update(inspections)..where((table) => table.id.equals(id))).write(
      const InspectionsCompanion(synced: Value(true)),
    );
  }

  Future<void> deleteInspection(int id) async {
    await (delete(inspections)..where((table) => table.id.equals(id))).go();
  }
}
