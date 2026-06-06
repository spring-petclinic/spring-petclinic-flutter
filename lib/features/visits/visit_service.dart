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

import '../../shared/network/api_client.dart';
import 'visit.dart';

class VisitService {
  VisitService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Visit>> listVisits() async {
    try {
      final data = await _apiClient.getJson('visits') as List<dynamic>;
      return data
          .map((item) => Visit.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  Future<Visit> getVisit(int visitId) async {
    final data =
        await _apiClient.getJson('visits/$visitId') as Map<String, dynamic>;
    return Visit.fromJson(data);
  }

  Future<Visit> createVisit(int ownerId, int petId, Visit visit) async {
    final data =
        await _apiClient.postJson(
              'owners/$ownerId/pets/$petId/visits',
              visit.toWriteJson(),
            )
            as Map<String, dynamic>;
    return Visit.fromJson(data);
  }

  Future<void> updateVisit(Visit visit) async {
    await _apiClient.putJson('visits/${visit.id}', visit.toWriteJson());
  }

  Future<void> deleteVisit(int visitId) async {
    await _apiClient.delete('visits/$visitId');
  }
}
