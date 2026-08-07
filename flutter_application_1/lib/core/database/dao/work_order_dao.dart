import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/work_orders_table.dart';

part 'work_order_dao.g.dart';

@DriftAccessor(tables: [WorkOrders])
class WorkOrderDao extends DatabaseAccessor<AppDatabase>
    with _$WorkOrderDaoMixin {
  WorkOrderDao(super.db);

  Future<void> saveWorkOrder(WorkOrdersCompanion workOrder) async {
    await into(workOrders).insertOnConflictUpdate(workOrder);
  }

  Future<void> saveWorkOrders(List<WorkOrdersCompanion> orders) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(workOrders, orders);
    });
  }

  Future<List<WorkOrder>> getAllWorkOrders() async {
    return select(workOrders).get();
  }

  Future<WorkOrder?> getWorkOrder(String id) async {
    return (select(
      workOrders,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> deleteWorkOrder(String id) async {
    await (delete(workOrders)..where((tbl) => tbl.id.equals(id))).go();
  }
}
