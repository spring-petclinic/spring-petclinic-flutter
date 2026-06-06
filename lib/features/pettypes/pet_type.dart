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

class PetType {
  const PetType({this.id, required this.name});

  final int? id;
  final String name;

  factory PetType.fromJson(Map<String, dynamic> json) {
    return PetType(id: json['id'] as int?, name: json['name'] as String? ?? '');
  }

  Map<String, dynamic> toJson() {
    return {if (id != null) 'id': id, 'name': name};
  }

  Map<String, dynamic> toWriteJson() {
    return {'name': name};
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PetType &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}
