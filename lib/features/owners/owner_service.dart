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
import 'owner.dart';
import 'owner_page.dart';

class OwnerService {
  OwnerService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Owner>> listOwners({String? lastName}) async {
    try {
      final data =
          await _apiClient.getJson(
                'owners',
                queryParameters: {'lastName': lastName},
              )
              as List<dynamic>;
      return data
          .map((item) => Owner.fromJson(item as Map<String, dynamic>))
          .toList();
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  Future<OwnerPage> listOwnersPage({
    String? lastName,
    required int page,
    required int size,
  }) async {
    final data =
        await _apiClient.getJson(
              'v2/owners',
              queryParameters: {
                'lastName': lastName,
                'page': page.toString(),
                'size': size.toString(),
              },
            )
            as Map<String, dynamic>;
    return OwnerPage.fromJson(data);
  }

  Future<Owner> getOwner(int ownerId) async {
    final data =
        await _apiClient.getJson('owners/$ownerId') as Map<String, dynamic>;
    return Owner.fromJson(data);
  }

  Future<Owner> createOwner(Owner owner) async {
    final data =
        await _apiClient.postJson('owners', owner.toWriteJson())
            as Map<String, dynamic>;
    return Owner.fromJson(data);
  }

  Future<void> updateOwner(Owner owner) async {
    await _apiClient.putJson('owners/${owner.id}', owner.toWriteJson());
  }

  Future<void> deleteOwner(int ownerId) async {
    await _apiClient.delete('owners/$ownerId');
  }
}
