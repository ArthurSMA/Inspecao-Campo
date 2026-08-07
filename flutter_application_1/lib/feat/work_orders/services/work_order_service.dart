import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import 'package:flutter_application_1/core/database/app_database.dart' as db;
import 'package:flutter_application_1/core/database/dao/work_order_dao.dart';
import 'package:flutter_application_1/core/network/api_client.dart';
import 'package:flutter_application_1/feat/work_orders/data/models/work_order.dart'
    as api_work_order;

class WorkOrderService {
  WorkOrderService(this._apiClient, this._workOrderDao);

  final ApiClient _apiClient;
  final WorkOrderDao _workOrderDao;
  WorkOrderDataSource? _lastDataSource;

  WorkOrderDataSource? get lastDataSource => _lastDataSource;

  Future<List<api_work_order.WorkOrder>> getWorkOrders({
    required String accessToken,
  }) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/work-orders',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      final data = response.data;

      if (data == null) {
        throw const WorkOrderException(
          'A API retornou dados em formato inesperado.',
          kind: WorkOrderErrorKind.invalidData,
        );
      }

      final workOrders = data
          .map(
            (item) =>
                api_work_order.WorkOrder.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);

      await _workOrderDao.saveWorkOrders(
        workOrders.map(_toCompanion).toList(growable: false),
      );

      _lastDataSource = WorkOrderDataSource.remote;

      return workOrders;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const WorkOrderException(
          'Sua sessão expirou. Entre novamente.',
          kind: WorkOrderErrorKind.unauthorized,
        );
      }

      if (error.response?.statusCode == 404) {
        throw const WorkOrderException(
          'Não foi possível carregar as ordens de serviço.',
          kind: WorkOrderErrorKind.server,
        );
      }

      if (_isConnectionError(error)) {
        return _loadCachedWorkOrders();
      }

      throw const WorkOrderException(
        'Não foi possível carregar as ordens de serviço.',
        kind: WorkOrderErrorKind.server,
      );
    } on FormatException {
      throw const WorkOrderException(
        'A API retornou dados em formato inesperado.',
        kind: WorkOrderErrorKind.invalidData,
      );
    } on TypeError {
      throw const WorkOrderException(
        'A API retornou dados em formato inesperado.',
        kind: WorkOrderErrorKind.invalidData,
      );
    } on WorkOrderException {
      rethrow;
    } catch (_) {
      throw const WorkOrderException(
        'Ocorreu um erro inesperado ao carregar as ordens.',
        kind: WorkOrderErrorKind.unknown,
      );
    }
  }

  bool _isConnectionError(DioException error) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }

  Future<List<api_work_order.WorkOrder>> _loadCachedWorkOrders() async {
    final cachedOrders = await _workOrderDao.getAllWorkOrders();

    if (cachedOrders.isEmpty) {
      throw const WorkOrderException(
        'Não foi possível acessar a API e não há ordens salvas no dispositivo.',
        kind: WorkOrderErrorKind.connection,
      );
    }

    _lastDataSource = WorkOrderDataSource.cache;

    return cachedOrders
        .map(
          (workOrder) => api_work_order.WorkOrder(
            id: workOrder.id,
            code: workOrder.code,
            title: workOrder.title,
            description: workOrder.description,
            address: workOrder.address,
            priority: workOrder.priority,
            status: workOrder.status,
            latitude: workOrder.latitude,
            longitude: workOrder.longitude,
            scheduledAt: workOrder.scheduledAt,
            updatedAt: workOrder.updatedAt,
            notes: workOrder.notes,
          ),
        )
        .toList(growable: false);
  }

  db.WorkOrdersCompanion _toCompanion(api_work_order.WorkOrder workOrder) {
    return db.WorkOrdersCompanion(
      id: Value(workOrder.id),
      code: Value(workOrder.code),
      title: Value(workOrder.title),
      description: Value(workOrder.description),
      address: Value(workOrder.address),
      priority: Value(workOrder.priority),
      status: Value(workOrder.status),
      latitude: Value(workOrder.latitude),
      longitude: Value(workOrder.longitude),
      scheduledAt: Value(workOrder.scheduledAt),
      updatedAt: Value(workOrder.updatedAt),
      notes: Value(workOrder.notes),
    );
  }
}

enum WorkOrderDataSource { remote, cache }

enum WorkOrderErrorKind {
  unauthorized,
  connection,
  server,
  invalidData,
  unknown,
}

class WorkOrderException implements Exception {
  const WorkOrderException(this.message, {required this.kind});

  final String message;
  final WorkOrderErrorKind kind;

  bool get shouldClearSession => kind == WorkOrderErrorKind.unauthorized;

  @override
  String toString() => message;
}
