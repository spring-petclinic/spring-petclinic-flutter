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

import 'package:flutter_test/flutter_test.dart';
import 'package:spring_petclinic_flutter/shared/forms/app_validators.dart';

void main() {
  group('AppValidators.exactDigits', () {
    final validator = AppValidators.exactDigits('Telephone', length: 10);

    test('accepts exactly 10 digits', () {
      expect(validator('1234567890'), isNull);
    });

    test('rejects fewer than 10 digits', () {
      expect(validator('12345'), 'Telephone must be exactly 10 digits long.');
    });

    test('rejects non-digit characters', () {
      expect(validator('12345abcde'), 'Telephone must contain digits only.');
    });
  });

  group('AppValidators.petBirthDate', () {
    final today = DateTime(2026, 5, 13);
    late StringValidator validator;

    setUp(() {
      validator = AppValidators.petBirthDate('Birth date', today: today);
    });

    test('accepts a date within the last 50 years', () {
      expect(validator('2020-01-01'), isNull);
    });

    test('accepts exactly 50 years ago', () {
      expect(validator('1976-05-13'), isNull);
    });

    test('rejects a missing date', () {
      expect(validator(''), 'Birth date is required.');
    });

    test('rejects an invalid date value', () {
      expect(validator('2020-02-30'), 'Birth date must be a valid date.');
    });

    test('rejects a future date', () {
      expect(validator('2026-05-14'), 'Birth date cannot be in the future.');
    });

    test('rejects a date older than 50 years', () {
      expect(
        validator('1976-05-12'),
        'Birth date cannot be older than 50 years.',
      );
    });
  });
}
