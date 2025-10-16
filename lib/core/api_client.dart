import 'dart:async';	
import 'dart:convert';	
import 'dart:io';	
import 'package:http/http.dart' as http;	
import 'package:flutter/foundation.dart';	
class ApiClient {
static final ApiClient _instance = ApiClient._internal();
factory ApiClient() => _instance;
ApiClient._internal();

// Cliente HTTP reutilizável com connection pooling
static final http.Client _client = http.Client();

// Cache para reduzir acessos
final Map<String, CachedResponse> _cache = {};

// Headers base otimizados
static const Map<String, String> _baseHeaders = {
'Content-Type': 'application/json',
'Accept': 'application/json',
'Connection': 'keep-alive',
};

// Configurações de timeout
static const Duration _defaultTimeout = Duration(seconds: 15);
static const Duration _longTimeout = Duration(seconds: 30);

/// GET request otimizado
Future<T> get<T>(
String endpoint, {
required String token,
Duration? timeout,
bool useCache = false,
Duration cacheTtl = const Duration(minutes: 5),
required T Function(Map<String, dynamic>) fromJson,
}) async {
final cacheKey = '$endpoint-$token';


// Verificar cache
if (useCache && _cache.containsKey(cacheKey)) {
  final cached = _cache[cacheKey]!;
  if (!cached.isExpired) {
    return cached.data as T;
  }
  _cache.remove(cacheKey);
}

final response = await _makeRequest(
  'GET',
  endpoint,
  token: token,
  timeout: timeout ?? _defaultTimeout,
);

final data = await _parseJsonInIsolate(response.body);
final result = fromJson(data);

// Armazenar em cache se solicitado
if (useCache) {
  _cache[cacheKey] = CachedResponse(result, DateTime.now().add(cacheTtl));
}

return result;
}

/// POST request otimizado
Future<T> post<T>(
String endpoint, {
required String token,
Map<String, dynamic>? body,
Duration? timeout,
required T Function(Map<String, dynamic>) fromJson,
}) async {
final response = await _makeRequest(
'POST',
endpoint,
token: token,
body: body,
timeout: timeout ?? _defaultTimeout,
);


final data = await _parseJsonInIsolate(response.body);
return fromJson(data);
}

/// PUT request otimizado
Future<T> put<T>(
String endpoint, {
required String token,
Map<String, dynamic>? body,
Duration? timeout,
required T Function(Map<String, dynamic>) fromJson,
}) async {
final response = await _makeRequest(
'PUT',
endpoint,
token: token,
body: body,
timeout: timeout ?? _defaultTimeout,
);


final data = await _parseJsonInIsolate(response.body);
return fromJson(data);
}

/// DELETE request otimizado
Future<bool> delete(
String endpoint, {
required String token,
Duration? timeout,
}) async {
final response = await _makeRequest(
'DELETE',
endpoint,
token: token,
timeout: timeout ?? _defaultTimeout,
);


return response.statusCode >= 200 && response.statusCode < 300;
}

/// Método interno para fazer requisições
Future<http.Response> _makeRequest(
String method,
String endpoint, {
required String token,
Map<String, dynamic>? body,
required Duration timeout,
}) async {
final url = Uri.parse(endpoint);
final headers = {
..._baseHeaders,
'Authorization': 'Bearer $token',
};

try {
  late http.Response response;

  switch (method) {
    case 'GET':
      response = await _client.get(url, headers: headers)
          .timeout(timeout, onTimeout: () => _timeoutResponse());
      break;
    case 'POST':
      response = await _client.post(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ).timeout(timeout, onTimeout: () => _timeoutResponse());
      break;
    case 'PUT':
      response = await _client.put(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ).timeout(timeout, onTimeout: () => _timeoutResponse());
      break;
    case 'DELETE':
      response = await _client.delete(url, headers: headers)
          .timeout(timeout, onTimeout: () => _timeoutResponse());
      break;
    default:
      throw ArgumentError('Método HTTP não suportado: $method');
  }

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return response;
  }

  throw _handleHttpError(response);
} on SocketException {
  throw const ApiException('Sem conexão com a internet');
} on TimeoutException {
  throw const ApiException('Tempo limite de requisição excedido');
} on FormatException catch (e) {
  throw ApiException('Erro ao processar resposta: ${e.message}');
}
}

/// Parse JSON em isolate separado para melhor performance
Future<Map<String, dynamic>> _parseJsonInIsolate(String body) async {
if (body.isEmpty) return {};


try {
  return await compute(_parseJson, body);
} catch (e) {
  throw ApiException('Erro ao decodificar JSON: $e');
}
}

/// Função estática para isolate
static Map<String, dynamic> _parseJson(String body) {
final decoded = json.decode(body);
return decoded is Map<String, dynamic> ? decoded : {};
}

/// Resposta de timeout padronizada
http.Response _timeoutResponse() {
return http.Response('{""error"": ""Request timeout""}', 408);
}

/// Tratamento centralizado de erros HTTP
ApiException _handleHttpError(http.Response response) {
try {
final data = json.decode(response.body);
final message = data['message'] ?? data['error'] ?? 'Erro desconhecido';


  switch (response.statusCode) {
    case 401:
      return ApiException('Token inválido ou expirado. Faça login novamente.', code: 401);
    case 403:
      return ApiException('Acesso negado.', code: 403);
    case 404:
      return ApiException('Recurso não encontrado.', code: 404);
    case 422:
      return ApiException('Dados inválidos: $message', code: 422);
    case 500:
      return ApiException('Erro interno do servidor.', code: 500);
    default:
      return ApiException('Erro HTTP ${response.statusCode}: $message', code: response.statusCode);
  }
} catch (e) {
  return ApiException('Erro HTTP ${response.statusCode}', code: response.statusCode);
}
}

/// Limpar cache
void clearCache() {
_cache.clear();
}

/// Fechar cliente HTTP
void dispose() {
_client.close();
_cache.clear();
}
}

/// Classe para cache de respostas
class CachedResponse {
final dynamic data;
final DateTime timestamp;
final Duration ttl;

CachedResponse(this.data, DateTime expiry)
: timestamp = DateTime.now(),
ttl = expiry.difference(DateTime.now());

bool get isExpired => DateTime.now().isAfter(timestamp.add(ttl));
}

/// Exception customizada para APIs
class ApiException implements Exception {
final String message;
final int? code;

const ApiException(this.message, {this.code});

@override
String toString() => code != null ? 'ApiException ($code): $message' : 'ApiException: $message';
}