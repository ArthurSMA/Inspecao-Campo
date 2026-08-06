import 'package:dio/dio.dart';

import 'package:flutter_application_1/core/network/api_client.dart';
import 'package:flutter_application_1/feat/auth/data/models/login_response.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );

      final data = response.data;

      if (data == null) {
        throw const AuthException('A API retornou uma resposta vazia.');
      }

      return LoginResponse.fromJson(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const AuthException('E-mail ou senha inválidos.');
      }

      if (error.response?.statusCode == 404) {
        throw const AuthException('A rota de login não foi encontrada.');
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const AuthException('A conexão com a API demorou demais.');
      }

      if (error.type == DioExceptionType.connectionError) {
        throw const AuthException(
          'Não foi possível acessar a API. Verifique o servidor e a URL.',
        );
      }

      if (error.type == DioExceptionType.badResponse) {
        throw AuthException(
          'A API respondeu com erro ${error.response?.statusCode}.',
        );
      }

      throw const AuthException('Erro inesperado ao comunicar com a API.');
    } on FormatException {
      throw const AuthException('A resposta da API possui formato inválido.');
    } on TypeError {
      throw const AuthException(
        'A resposta da API contém dados em formato inesperado.',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Ocorreu um erro inesperado durante o login.');
    }
  }

  Future<AuthUser> getCurrentUser(String accessToken) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = response.data;
      if (data == null) {
        throw const AuthException('A API retornou uma resposta vazia.');
      }
      return AuthUser.fromJson(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const AuthException(
          'Sua sessão expirou. Entre novamente.',
          shouldClearSession: true,
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const AuthException('A conexão com a API demorou demais.');
      }
      if (error.type == DioExceptionType.connectionError) {
        throw const AuthException('Não foi possível validar sua sessão.');
      }
      throw const AuthException('Erro ao validar sua sessão.');
    } on FormatException {
      throw const AuthException(
        'A resposta da sessão possui formato inválido.',
        shouldClearSession: true,
      );
    } on TypeError {
      throw const AuthException(
        'A resposta da sessão contém dados inesperados.',
        shouldClearSession: true,
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Erro inesperado ao validar sua sessão.');
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message, {this.shouldClearSession = false});

  final String message;
  final bool shouldClearSession;

  @override
  String toString() => message;
}
