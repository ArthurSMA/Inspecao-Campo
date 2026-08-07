import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/core/database/app_database.dart' as db;
import 'package:flutter_application_1/core/database/dao/user_dao.dart';
import 'package:flutter_application_1/core/database/dao/work_order_dao.dart';
import 'package:flutter_application_1/core/network/api_client.dart';
import 'package:flutter_application_1/feat/auth/services/auth_service.dart';
import 'package:flutter_application_1/feat/work_orders/services/work_order_service.dart';

void main() {
  late db.AppDatabase database;
  late WorkOrderDao workOrderDao;
  late UserDao userDao;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    workOrderDao = WorkOrderDao(database);
    userDao = UserDao(database);
  });

  tearDown(() => database.close());

  test('ordens remotas são persistidas no cache local', () async {
    final client = _apiClient((_) => _jsonResponse(200, [_workOrderJson()]));
    final service = WorkOrderService(client, workOrderDao);

    final orders = await service.getWorkOrders(accessToken: 'token');
    final cachedOrders = await workOrderDao.getAllWorkOrders();

    expect(orders, hasLength(1));
    expect(cachedOrders.single.id, 'wo_1001');
    expect(cachedOrders.single.notes, 'Observação da ordem');
    expect(service.lastDataSource, WorkOrderDataSource.remote);
  });

  test('falha de conexão retorna ordens previamente cacheadas', () async {
    await workOrderDao.saveWorkOrder(_workOrderCompanion());
    final client = _apiClient((options) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    });
    final service = WorkOrderService(client, workOrderDao);

    final orders = await service.getWorkOrders(accessToken: 'token');

    expect(orders.single.id, 'wo_1001');
    expect(service.lastDataSource, WorkOrderDataSource.cache);
  });

  test('HTTP 401 não é escondido pelo cache local', () async {
    await workOrderDao.saveWorkOrder(_workOrderCompanion());
    final client = _apiClient(
      (_) => _jsonResponse(401, {'message': 'Não autorizado'}),
    );
    final service = WorkOrderService(client, workOrderDao);

    expect(
      () => service.getWorkOrders(accessToken: 'token-invalido'),
      throwsA(
        isA<WorkOrderException>().having(
          (error) => error.shouldClearSession,
          'shouldClearSession',
          isTrue,
        ),
      ),
    );
  });

  test('falha de conexão sem cache retorna mensagem legível', () async {
    final client = _apiClient((options) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    });
    final service = WorkOrderService(client, workOrderDao);

    expect(
      () => service.getWorkOrders(accessToken: 'token'),
      throwsA(
        isA<WorkOrderException>().having(
          (error) => error.message,
          'message',
          contains('não há ordens salvas'),
        ),
      ),
    );
  });

  test(
    'sessão existente restaura usuário local quando a API está offline',
    () async {
      await userDao.saveUser(
        const db.UsersCompanion(
          id: Value('u_001'),
          name: Value('Ana Técnica'),
          email: Value('tecnico@orbytis.com.br'),
          role: Value('field_technician'),
        ),
      );
      final client = _apiClient((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      });

      final user = await AuthService(client, userDao).getCurrentUser('token');

      expect(user.id, 'u_001');
      expect(user.name, 'Ana Técnica');
    },
  );

  test('HTTP 401 na sessão não restaura usuário local', () async {
    await userDao.saveUser(
      const db.UsersCompanion(
        id: Value('u_001'),
        name: Value('Ana Técnica'),
        email: Value('tecnico@orbytis.com.br'),
        role: Value('field_technician'),
      ),
    );
    final client = _apiClient(
      (_) => _jsonResponse(401, {'message': 'Token expirado'}),
    );

    expect(
      () => AuthService(client, userDao).getCurrentUser('token-invalido'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.shouldClearSession,
          'shouldClearSession',
          isTrue,
        ),
      ),
    );
  });
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

Map<String, Object> _workOrderJson() {
  return {
    'id': 'wo_1001',
    'code': 'OS-2026-001',
    'title': 'Inspeção de poste',
    'description': 'Verificar estado do poste.',
    'address': 'Rua das Acácias, 120',
    'priority': 'high',
    'status': 'open',
    'latitude': -7.1195,
    'longitude': -34.845,
    'scheduledAt': '2026-07-28T13:00:00.000Z',
    'updatedAt': '2026-07-26T12:00:00.000Z',
    'notes': 'Observação da ordem',
  };
}

db.WorkOrdersCompanion _workOrderCompanion() {
  return db.WorkOrdersCompanion.insert(
    id: 'wo_1001',
    code: 'OS-2026-001',
    title: 'Inspeção de poste',
    description: 'Verificar estado do poste.',
    address: 'Rua das Acácias, 120',
    priority: 'high',
    status: 'open',
    latitude: -7.1195,
    longitude: -34.845,
    scheduledAt: DateTime.parse('2026-07-28T13:00:00.000Z'),
    updatedAt: DateTime.parse('2026-07-26T12:00:00.000Z'),
    notes: 'Observação da ordem',
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
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
