import 'package:flutter_application_1/core/database/dao/inspection_dao.dart';
import 'package:flutter_application_1/feat/inspection/data/models/inspection.dart';
import 'package:flutter_application_1/feat/inspection/services/inspection_service.dart';

class InspectionSyncService {
  InspectionSyncService(this._inspectionDao, this._inspectionService);

  final InspectionDao _inspectionDao;
  final InspectionService _inspectionService;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  Future<InspectionSyncResult> syncPendingInspections({
    required String accessToken,
    String? onlyClientId,
  }) async {
    if (_isSyncing) return const InspectionSyncResult.skipped();
    _isSyncing = true;
    var synced = 0;
    var failed = 0;
    try {
      final queued = await _inspectionDao.getPendingAndFailed();
      final selected = onlyClientId == null
          ? queued
          : queued.where((row) => row.clientId == onlyClientId).toList();

      for (final row in selected) {
        final inspection = InspectionModel.fromDatabase(row);
        await _inspectionDao.markAsPending(inspection.clientId);
        try {
          final response = await _inspectionService.submitInspection(
            accessToken: accessToken,
            inspection: inspection,
          );
          await _inspectionDao.markAsSynced(inspection.clientId, response.id);
          synced++;
        } on InspectionException catch (error) {
          await _inspectionDao.markAsFailed(inspection.clientId, error.message);
          failed++;
          if (error.shouldClearSession) rethrow;
        }
      }
      return InspectionSyncResult(synced: synced, failed: failed);
    } finally {
      _isSyncing = false;
    }
  }

  Future<InspectionSyncResult> retry({
    required String accessToken,
    required String clientId,
  }) async {
    await _inspectionDao.markAsPending(clientId);
    return syncPendingInspections(
      accessToken: accessToken,
      onlyClientId: clientId,
    );
  }
}

class InspectionSyncResult {
  const InspectionSyncResult({required this.synced, required this.failed})
    : skipped = false;

  const InspectionSyncResult.skipped() : synced = 0, failed = 0, skipped = true;

  final int synced;
  final int failed;
  final bool skipped;
}
