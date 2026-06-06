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
import 'pet.dart';

class PetService {
  PetService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Pet>> listPets() async {
    try {
      final data = await _apiClient.getJson('pets') as List<dynamic>;
      return data
          .map((item) => Pet.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  Future<Pet> getPet(int petId) async {
    final data =
        await _apiClient.getJson('pets/$petId') as Map<String, dynamic>;
    return Pet.fromJson(data);
  }

  Future<Pet> createPet(int ownerId, Pet pet) async {
    final data =
        await _apiClient.postJson('owners/$ownerId/pets', pet.toWriteJson())
            as Map<String, dynamic>;
    return Pet.fromJson(data);
  }

  Future<void> updatePet(Pet pet) async {
    await _apiClient.putJson('pets/${pet.id}', pet.toWriteJson());
  }

  Future<void> deletePet(int petId) async {
    await _apiClient.delete('pets/$petId');
  }
}
