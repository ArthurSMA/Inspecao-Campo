// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_dao.dart';

// ignore_for_file: type=lint
mixin _$InspectionDaoMixin on DatabaseAccessor<AppDatabase> {
  $InspectionsTable get inspections => attachedDatabase.inspections;
  InspectionDaoManager get managers => InspectionDaoManager(this);
}

class InspectionDaoManager {
  final _$InspectionDaoMixin _db;
  InspectionDaoManager(this._db);
  $$InspectionsTableTableManager get inspections =>
      $$InspectionsTableTableManager(_db.attachedDatabase, _db.inspections);
}
