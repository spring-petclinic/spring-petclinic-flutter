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
import 'pet_type.dart';

class PetTypeService {
  PetTypeService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PetType>> listPetTypes() async {
    try {
      final data = await _apiClient.getJson('pettypes') as List<dynamic>;
      return data
          .map((item) => PetType.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  Future<PetType> getPetType(int typeId) async {
    final data =
        await _apiClient.getJson('pettypes/$typeId') as Map<String, dynamic>;
    return PetType.fromJson(data);
  }

  Future<PetType> createPetType(PetType petType) async {
    final data =
        await _apiClient.postJson('pettypes', petType.toWriteJson())
            as Map<String, dynamic>;
    return PetType.fromJson(data);
  }

  Future<void> updatePetType(PetType petType) async {
    await _apiClient.putJson('pettypes/${petType.id}', petType.toJson()); // Fix: use toJson() to include id in request body
  }

  Future<void> deletePetType(int typeId) async {
    await _apiClient.delete('pettypes/$typeId');
  }
}