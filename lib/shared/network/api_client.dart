/*
 * Copyright 2002-2017 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  static const Duration _requestTimeout = Duration(seconds: 10);

  final http.Client _client;
  final String _baseUrl;

  Future<dynamic> getJson(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) {
    return _send('GET', _buildUri(path, queryParameters: queryParameters));
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) {
    return _send('POST', _buildUri(path), body: body);
  }

  Future<dynamic> putJson(String path, Map<String, dynamic> body) {
    return _send('PUT', _buildUri(path), body: body);
  }

  Future<void> delete(String path) async {
    await _send('DELETE', _buildUri(path));
  }

  Uri _buildUri(
    String path, {
    Map<String, String?> queryParameters = const {},
  }) {
    final cleanQueryParameters = <String, String>{};
    for (final entry in queryParameters.entries) {
      final value = entry.value?.trim();
      if (value != null && value.isNotEmpty) {
        cleanQueryParameters[entry.key] = value;
      }
    }

    return Uri.parse('$_baseUrl/$path').replace(
      queryParameters: cleanQueryParameters.isEmpty
          ? null
          : cleanQueryParameters,
    );
  }

  Future<dynamic> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';

    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    late final http.StreamedResponse streamedResponse;
    late final http.Response response;

    try {
      streamedResponse = await _client.send(request).timeout(_requestTimeout);
      response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(_requestTimeout);
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on http.ClientException catch (_) {
      throw ApiException('Unable to reach the server. Please try again.');
    } catch (_) {
      throw ApiException('Unexpected network error. Please try again.');
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        _extractMessage(response),
        statusCode: response.statusCode,
      );
    }

    final responseBody = response.body.trim();
    if (responseBody.isEmpty) {
      return null;
    }

    return jsonDecode(responseBody);
  }

  String _extractMessage(http.Response response) {
    final errorsHeader = response.headers['errors'];
    if (errorsHeader != null && errorsHeader.isNotEmpty) {
      try {
        final decoded = jsonDecode(errorsHeader);
        if (decoded is List && decoded.isNotEmpty) {
          final firstError = decoded.first;
          if (firstError is Map<String, dynamic>) {
            final headerMessage = firstError['errorMessage'];
            if (headerMessage is String && headerMessage.isNotEmpty) {
              return headerMessage;
            }
          }
        }
      } catch (_) {
        // Fall back to the response body.
      }
    }

    final responseBody = response.body.trim();
    if (responseBody.isEmpty) {
      return 'Request failed with status ${response.statusCode}.';
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        // Surface the first useful validation message from
        // schemaValidationErrors in ProblemDetail responses.
        final schemaErrors = decoded['schemaValidationErrors'];
        if (schemaErrors is List && schemaErrors.isNotEmpty) {
          final first = schemaErrors.first;
          if (first is Map<String, dynamic>) {
            final fieldMsg = first['message'] ?? first['defaultMessage'];
            if (fieldMsg is String && fieldMsg.isNotEmpty) {
              return fieldMsg;
            }
          }
        }

        for (final key in ['detail', 'message', 'title', 'error']) {
          final value = decoded[key];
          if (value is String && value.isNotEmpty) {
            return value;
          }
        }
      }

      if (decoded is List && decoded.isNotEmpty) {
        final firstItem = decoded.first;
        if (firstItem is Map<String, dynamic>) {
          final value = firstItem['message'] ?? firstItem['errorMessage'];
          if (value is String && value.isNotEmpty) {
            return value;
          }
        }
      }
    } catch (_) {
      return responseBody;
    }

    return responseBody;
  }
}
