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

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spring_petclinic_flutter/shared/network/api_client.dart';

void main() {
  group('ApiClient error parsing', () {
    ApiClient buildApiClient({
      required Future<http.Response> Function(http.Request request) handler,
    }) {
      return ApiClient(
        client: MockClient(handler),
        baseUrl: 'http://localhost',
      );
    }

    test('extracts first schemaValidationErrors message', () async {
      final body = jsonEncode({
        'type': 'about:blank',
        'title': 'Bad Request',
        'status': 400,
        'detail': 'Validation failed',
        'schemaValidationErrors': [
          {'field': 'name', 'message': 'must not be blank'},
          {'field': 'birthDate', 'message': 'must not be null'},
        ],
      });

      final apiClient = buildApiClient(
        handler: (_) async => http.Response(body, 400),
      );

      expect(
        apiClient.getJson('pets'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'must not be blank')
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });

    test('uses defaultMessage when message is absent', () async {
      final body = jsonEncode({
        'type': 'about:blank',
        'title': 'Bad Request',
        'status': 400,
        'detail': 'Validation failed',
        'schemaValidationErrors': [
          {
            'field': 'firstName',
            'defaultMessage': 'size must be between 1 and 30',
          },
        ],
      });

      final apiClient = buildApiClient(
        handler: (_) async => http.Response(body, 400),
      );

      expect(
        apiClient.getJson('owners'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'size must be between 1 and 30',
          ),
        ),
      );
    });

    test('falls back to detail when schemaValidationErrors is empty', () async {
      final body = jsonEncode({
        'type': 'about:blank',
        'title': 'Bad Request',
        'status': 400,
        'detail': 'Validation failed',
        'schemaValidationErrors': [],
      });

      final apiClient = buildApiClient(
        handler: (_) async => http.Response(body, 400),
      );

      expect(
        apiClient.getJson('owners'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Validation failed',
          ),
        ),
      );
    });

    test(
      'falls back to detail when schemaValidationErrors is absent',
      () async {
        final body = jsonEncode({
          'type': 'about:blank',
          'title': 'Bad Request',
          'status': 400,
          'detail': 'Request body is invalid',
        });

        final apiClient = buildApiClient(
          handler: (_) async => http.Response(body, 400),
        );

        expect(
          apiClient.getJson('owners'),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Request body is invalid',
            ),
          ),
        );
      },
    );

    test('handles non-ProblemDetail error bodies', () async {
      final apiClient = buildApiClient(
        handler: (_) async => http.Response('Something went wrong', 500),
      );

      expect(
        apiClient.getJson('pets'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Something went wrong')
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });
}
