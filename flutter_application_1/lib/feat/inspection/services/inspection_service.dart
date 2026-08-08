import 'dart:io';

import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/network/api_client.dart';
import 'package:flutter_application_1/feat/inspection/data/models/inspection.dart';
import 'package:flutter_application_1/feat/inspection/data/models/inspection_response.dart';

class InspectionService {
  InspectionService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<InspectionResponse>> getInspections(String accessToken) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        '/inspections',
        options: Options(headers: _authorization(accessToken)),
      );
      return (response.data ?? const [])
          .map(
            (item) => InspectionResponse.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw _fromDio(error);
    } on TypeError {
      throw const InspectionException(
        'A API retornou inspeções em formato inesperado.',
        kind: InspectionErrorKind.invalidData,
      );
    }
  }

  Future<InspectionResponse> submitInspection({
    required String accessToken,
    required InspectionModel inspection,
  }) async {
    final photoPath = inspection.photoPath;
    if (photoPath == null || !File(photoPath).existsSync()) {
      throw const InspectionException(
        'A foto da inspeção não foi encontrada no dispositivo.',
        kind: InspectionErrorKind.invalidData,
      );
    }
    if (inspection.latitude == null || inspection.longitude == null) {
      throw const InspectionException(
        'A localização da inspeção está incompleta.',
        kind: InspectionErrorKind.invalidData,
      );
    }

    final fields = <String, dynamic>{
      'clientId': inspection.clientId,
      'workOrderId': inspection.workOrderId,
      'observation': inspection.observation,
      'latitude': inspection.latitude,
      'longitude': inspection.longitude,
      'capturedAt': inspection.capturedAt.toUtc().toIso8601String(),
      'photo': await MultipartFile.fromFile(photoPath),
    };
    final condition = inspection.condition;
    if (condition != null && condition.isNotEmpty) {
      fields['condition'] = condition;
    }

    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/inspections',
        data: FormData.fromMap(fields),
        options: Options(
          headers: _authorization(accessToken),
          contentType: Headers.multipartFormDataContentType,
        ),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw const InspectionException(
          'A API não confirmou o envio da inspeção.',
          kind: InspectionErrorKind.server,
        );
      }
      final data = response.data;
      if (data == null) {
        throw const InspectionException(
          'A API retornou uma resposta vazia para a inspeção.',
          kind: InspectionErrorKind.invalidData,
        );
      }
      return InspectionResponse.fromJson(data);
    } on DioException catch (error) {
      throw _fromDio(error);
    } on TypeError {
      throw const InspectionException(
        'A API retornou a inspeção em formato inesperado.',
        kind: InspectionErrorKind.invalidData,
      );
    }
  }

  Map<String, String> _authorization(String token) => {
    'Authorization': 'Bearer $token',
  };

  InspectionException _fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return const InspectionException(
        'Sua sessão expirou. Entre novamente.',
        kind: InspectionErrorKind.unauthorized,
      );
    }
    if (statusCode == 400) {
      return InspectionException(
        _responseMessage(error) ?? 'A inspeção possui dados inválidos.',
        kind: InspectionErrorKind.invalidData,
      );
    }
    if (statusCode == 409) {
      return const InspectionException(
        'A ordem de serviço da inspeção não existe.',
        kind: InspectionErrorKind.invalidData,
      );
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const InspectionException(
        'Não foi possível enviar a inspeção. Verifique a conexão.',
        kind: InspectionErrorKind.connection,
      );
    }
    return InspectionException(
      _responseMessage(error) ?? 'Não foi possível enviar a inspeção.',
      kind: InspectionErrorKind.server,
    );
  }

  String? _responseMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) return data['message'] as String?;
    return null;
  }
}

enum InspectionErrorKind { unauthorized, connection, invalidData, server }

class InspectionException implements Exception {
  const InspectionException(this.message, {required this.kind});

  final String message;
  final InspectionErrorKind kind;

  bool get shouldClearSession => kind == InspectionErrorKind.unauthorized;

  @override
  String toString() => message;
}
