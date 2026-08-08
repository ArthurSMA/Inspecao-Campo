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

  Future<Inspection?> getInspectionByClientId(String clientId) {
    return (select(
      inspections,
    )..where((table) => table.clientId.equals(clientId))).getSingleOrNull();
  }

  Future<Inspection?> getDraftForWorkOrder(String workOrderId) {
    return (select(inspections)
          ..where(
            (table) =>
                table.workOrderId.equals(workOrderId) &
                table.status.equals('draft'),
          )
          ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]))
        .getSingleOrNull();
  }

  Future<List<Inspection>> getPendingAndFailed() {
    return (select(
      inspections,
    )..where((table) => table.status.isIn(['pending', 'failed']))).get();
  }

  Future<void> markAsPending(String clientId) async {
    await (update(
      inspections,
    )..where((table) => table.clientId.equals(clientId))).write(
      InspectionsCompanion(
        status: const Value('pending'),
        errorMessage: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markAsSynced(String clientId, String serverId) async {
    await (update(
      inspections,
    )..where((table) => table.clientId.equals(clientId))).write(
      InspectionsCompanion(
        status: const Value('synced'),
        serverId: Value(serverId),
        errorMessage: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markAsFailed(String clientId, String message) async {
    await (update(
      inspections,
    )..where((table) => table.clientId.equals(clientId))).write(
      InspectionsCompanion(
        status: const Value('failed'),
        errorMessage: Value(message),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteInspection(int id) async {
    await (delete(inspections)..where((table) => table.id.equals(id))).go();
  }
}
