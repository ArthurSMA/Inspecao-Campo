import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/network/api_client.dart';
import 'package:flutter_application_1/feat/work_orders/data/models/work_order.dart';

class WorkOrderService {
  WorkOrderService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<WorkOrder>> getWorkOrders({required String accessToken}) async {
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

      return data
          .map((item) => WorkOrder.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
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
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const WorkOrderException(
          'Não foi possível acessar a API.',
          kind: WorkOrderErrorKind.connection,
        );
      }
      if (error.type == DioExceptionType.connectionError) {
        throw const WorkOrderException(
          'Não foi possível acessar a API.',
          kind: WorkOrderErrorKind.connection,
        );
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
}

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
