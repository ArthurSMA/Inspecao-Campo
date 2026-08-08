import 'package:drift/drift.dart';

import 'package:flutter_application_1/core/database/app_database.dart' as db;

enum InspectionStatus { draft, pending, synced, failed }

class InspectionModel {
  const InspectionModel({
    this.id,
    required this.clientId,
    required this.workOrderId,
    required this.observation,
    this.condition,
    this.photoPath,
    this.latitude,
    this.longitude,
    required this.capturedAt,
    required this.status,
    this.serverId,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String clientId;
  final String workOrderId;
  final String observation;
  final String? condition;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final DateTime capturedAt;
  final InspectionStatus status;
  final String? serverId;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? get completionValidationError {
    if (observation.trim().length < 10) {
      return 'Informe uma observação com pelo menos 10 caracteres.';
    }
    if (photoPath == null || photoPath!.isEmpty) {
      return 'Adicione uma foto antes de concluir.';
    }
    if (latitude == null || longitude == null) {
      return 'Capture a localização antes de concluir.';
    }
    return null;
  }

  factory InspectionModel.fromDatabase(db.Inspection row) {
    return InspectionModel(
      id: row.id,
      clientId: row.clientId,
      workOrderId: row.workOrderId,
      observation: row.observation,
      condition: row.condition,
      photoPath: row.photoPath,
      latitude: row.latitude,
      longitude: row.longitude,
      capturedAt: row.capturedAt,
      status: InspectionStatus.values.byName(row.status),
      serverId: row.serverId,
      errorMessage: row.errorMessage,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  db.InspectionsCompanion toCompanion() {
    return db.InspectionsCompanion(
      id: id == null ? const Value.absent() : Value(id!),
      clientId: Value(clientId),
      workOrderId: Value(workOrderId),
      observation: Value(observation),
      condition: Value(condition),
      photoPath: Value(photoPath),
      latitude: Value(latitude),
      longitude: Value(longitude),
      capturedAt: Value(capturedAt),
      status: Value(status.name),
      serverId: Value(serverId),
      errorMessage: Value(errorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
