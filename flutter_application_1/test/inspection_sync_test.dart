import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/core/database/app_database.dart' as db;
import 'package:flutter_application_1/core/database/dao/inspection_dao.dart';
import 'package:flutter_application_1/core/network/api_client.dart';
import 'package:flutter_application_1/feat/inspection/data/models/inspection.dart';
import 'package:flutter_application_1/feat/inspection/data/models/inspection_response.dart';
import 'package:flutter_application_1/feat/inspection/presentation/pages/inspections_history_page.dart';
import 'package:flutter_application_1/feat/inspection/services/inspection_service.dart';
import 'package:flutter_application_1/feat/inspection/services/inspection_sync_service.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late db.AppDatabase database;
  late InspectionDao dao;
  late Directory tempDirectory;
  late File photo;

  setUp(() async {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    dao = InspectionDao(database);
    tempDirectory = await Directory.systemTemp.createTemp('inspection_test_');
    photo = File('${tempDirectory.path}${Platform.pathSeparator}photo.jpg');
    await photo.writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    await database.close();
    await tempDirectory.delete(recursive: true);
  });

  test('draft persiste e não entra na fila', () async {
    await dao.saveInspection(
      _inspection('draft-1', InspectionStatus.draft, photo.path).toCompanion(),
    );

    final remote = _FakeInspectionService();
    await InspectionSyncService(
      dao,
      remote,
    ).syncPendingInspections(accessToken: 'token');

    expect(await dao.getAllInspections(), hasLength(1));
    expect(await dao.getPendingAndFailed(), isEmpty);
    expect(remote.sentClientIds, isEmpty);
  });

  test('conclusão local persiste a inspeção como pending', () async {
    await dao.saveInspection(
      _inspection(
        'completed-local',
        InspectionStatus.pending,
        photo.path,
      ).toCompanion(),
    );

    expect(
      (await dao.getInspectionByClientId('completed-local'))?.status,
      'pending',
    );
  });

  test('pending e failed entram na fila, draft e synced não', () async {
    for (final status in InspectionStatus.values) {
      await dao.saveInspection(
        _inspection(status.name, status, photo.path).toCompanion(),
      );
    }

    final queued = await dao.getPendingAndFailed();

    expect(
      queued.map((item) => item.status),
      containsAll(['pending', 'failed']),
    );
    expect(queued, hasLength(2));
  });

  test(
    'sync salva serverId e preserva clientId para pending e failed',
    () async {
      await dao.saveInspection(
        _inspection(
          'client-pending',
          InspectionStatus.pending,
          photo.path,
        ).toCompanion(),
      );
      await dao.saveInspection(
        _inspection(
          'client-failed',
          InspectionStatus.failed,
          photo.path,
        ).toCompanion(),
      );
      final remote = _FakeInspectionService();
      final sync = InspectionSyncService(dao, remote);

      final result = await sync.syncPendingInspections(accessToken: 'token');

      expect(result.synced, 2);
      expect(remote.sentClientIds, ['client-pending', 'client-failed']);
      for (final clientId in remote.sentClientIds) {
        final saved = await dao.getInspectionByClientId(clientId);
        expect(saved?.status, 'synced');
        expect(saved?.serverId, 'server-$clientId');
        expect(saved?.errorMessage, isNull);
      }
    },
  );

  test('retry reutiliza clientId e não cria outro registro', () async {
    const clientId = 'stable-client-id';
    await dao.saveInspection(
      _inspection(clientId, InspectionStatus.failed, photo.path).toCompanion(),
    );
    final remote = _FakeInspectionService();
    final sync = InspectionSyncService(dao, remote);

    await sync.retry(accessToken: 'token', clientId: clientId);

    expect(remote.sentClientIds, [clientId]);
    expect(await dao.getAllInspections(), hasLength(1));
  });

  test('falha grava status failed e errorMessage', () async {
    const clientId = 'client-error';
    await dao.saveInspection(
      _inspection(clientId, InspectionStatus.pending, photo.path).toCompanion(),
    );
    final remote = _FakeInspectionService(
      error: const InspectionException(
        'API indisponível',
        kind: InspectionErrorKind.connection,
      ),
    );

    await InspectionSyncService(
      dao,
      remote,
    ).syncPendingInspections(accessToken: 'token');

    final saved = await dao.getInspectionByClientId(clientId);
    expect(saved?.status, 'failed');
    expect(saved?.errorMessage, 'API indisponível');
  });

  test('401 não marca inspeção como synced', () async {
    const clientId = 'client-401';
    await dao.saveInspection(
      _inspection(clientId, InspectionStatus.pending, photo.path).toCompanion(),
    );
    final remote = _FakeInspectionService(
      error: const InspectionException(
        'Sessão expirada',
        kind: InspectionErrorKind.unauthorized,
      ),
    );

    await expectLater(
      InspectionSyncService(
        dao,
        remote,
      ).syncPendingInspections(accessToken: 'token'),
      throwsA(isA<InspectionException>()),
    );
    expect((await dao.getInspectionByClientId(clientId))?.status, 'failed');
  });

  test('POST 200 e 201 são tratados como sucesso idempotente', () async {
    for (final statusCode in [200, 201]) {
      final client = _apiClient(
        (_) => _jsonResponse(statusCode, {
          'id': 'server-$statusCode',
          'clientId': 'client-http',
        }),
      );
      final response = await InspectionService(client).submitInspection(
        accessToken: 'token',
        inspection: _inspection(
          'client-http',
          InspectionStatus.pending,
          photo.path,
        ),
      );
      expect(response.id, 'server-$statusCode');
    }
  });

  test('inspeção incompleta não passa na validação de conclusão', () {
    final incomplete = _inspection(
      'incomplete',
      InspectionStatus.draft,
      null,
      observation: 'curta',
      latitude: null,
      longitude: null,
    );

    expect(incomplete.completionValidationError, isNotNull);
  });

  test('histórico filtra por status', () async {
    for (final status in InspectionStatus.values) {
      await dao.saveInspection(
        _inspection(status.name, status, photo.path).toCompanion(),
      );
    }
    final all = await dao.getAllInspections();

    expect(filterInspectionsByStatus(all, null), hasLength(4));
    expect(
      filterInspectionsByStatus(all, InspectionStatus.failed).single.status,
      'failed',
    );
  });

  test('inspeção sobrevive ao fechamento e reabertura do banco', () async {
    final databaseFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}persistent.sqlite',
    );
    var persistentDatabase = db.AppDatabase.forTesting(
      NativeDatabase(databaseFile),
    );
    await InspectionDao(persistentDatabase).saveInspection(
      _inspection(
        'persistent',
        InspectionStatus.draft,
        photo.path,
      ).toCompanion(),
    );
    await persistentDatabase.close();

    persistentDatabase = db.AppDatabase.forTesting(
      NativeDatabase(databaseFile),
    );
    final restored = await InspectionDao(
      persistentDatabase,
    ).getAllInspections();
    await persistentDatabase.close();

    expect(restored.single.clientId, 'persistent');
  });
}

InspectionModel _inspection(
  String clientId,
  InspectionStatus status,
  String? photoPath, {
  String observation = 'Observação válida para inspeção',
  double? latitude = -7.1,
  double? longitude = -34.8,
}) {
  final now = DateTime(2026, 8, 7, 12);
  return InspectionModel(
    clientId: clientId,
    workOrderId: 'wo_1001',
    observation: observation,
    condition: 'regular',
    photoPath: photoPath,
    latitude: latitude,
    longitude: longitude,
    capturedAt: now,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeInspectionService extends InspectionService {
  _FakeInspectionService({this.error}) : super(ApiClient());

  final InspectionException? error;
  final List<String> sentClientIds = [];

  @override
  Future<InspectionResponse> submitInspection({
    required String accessToken,
    required InspectionModel inspection,
  }) async {
    sentClientIds.add(inspection.clientId);
    final error = this.error;
    if (error != null) throw error;
    return InspectionResponse(
      id: 'server-${inspection.clientId}',
      clientId: inspection.clientId,
    );
  }
}

ApiClient _apiClient(_ResponseHandler handler) {
  final client = ApiClient();
  client.dio.httpClientAdapter = _StubAdapter(handler);
  return client;
}

ResponseBody _jsonResponse(int statusCode, Object body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

typedef _ResponseHandler =
    FutureOr<ResponseBody> Function(RequestOptions options);

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._handler);

  final _ResponseHandler _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
