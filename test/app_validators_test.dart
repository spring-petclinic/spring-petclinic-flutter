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

  group('AppValidators.firstName', () {
    final validator = AppValidators.firstName(
      'First name',
      minLength: 2,
      maxLength: 30,
    );

    test('accepts standard names', () {
      expect(validator('John'), isNull);
      expect(validator('Carter'), isNull);
    });

    test('accepts Unicode/diacritics characters like José', () {
      expect(validator('José'), isNull);
      expect(validator('Müller'), isNull);
      expect(validator('François'), isNull);
    });

    test('accepts spaces like Mary Jane', () {
      expect(validator('Mary Jane'), isNull);
    });

    test('accepts hyphens like Anne-Marie', () {
      expect(validator('Anne-Marie'), isNull);
      expect(validator('John-Doe'), isNull);
    });

    test('accepts apostrophes like O\'Connor', () {
      expect(validator('O\'Connor'), isNull);
      expect(validator('D\'Angelo'), isNull);
    });

    test('rejects periods at the end', () {
      expect(validator('George.'), 'First name must contain letters only.');
      expect(validator('Jr.'), 'First name must contain letters only.');
    });

    test('rejects values with digits', () {
      expect(validator('John3'), 'First name must contain letters only.');
    });

    test('rejects values with invalid special characters', () {
      expect(validator('Carter_'), 'First name must contain letters only.');
      expect(validator('John#'), 'First name must contain letters only.');
    });

    test('rejects values shorter than minLength', () {
      expect(validator('A'), 'First name must be at least 2 character long.');
    });

    test('rejects values longer than maxLength', () {
      expect(
        validator('A' * 31),
        'First name may be at most 30 characters long.',
      );
    });

    test('rejects empty values', () {
      expect(validator(''), 'First name is required.');
      expect(validator(null), 'First name is required.');
    });
  });

  group('AppValidators.lastName', () {
    final validator = AppValidators.lastName(
      'Last name',
      minLength: 2,
      maxLength: 30,
    );

    test('accepts standard names', () {
      expect(validator('John'), isNull);
      expect(validator('Carter'), isNull);
    });

    test('accepts Unicode/diacritics characters like José', () {
      expect(validator('José'), isNull);
    });

    test('accepts spaces like Mary Jane', () {
      expect(validator('Mary Jane'), isNull);
    });

    test('accepts hyphens like Anne-Marie', () {
      expect(validator('Anne-Marie'), isNull);
    });

    test('accepts apostrophes like O\'Connor', () {
      expect(validator('O\'Connor'), isNull);
    });

    test('accepts periods at the end', () {
      expect(validator('Jr.'), isNull);
      expect(validator('Smith.'), isNull);
    });

    test('rejects values with digits', () {
      expect(validator('John3'), 'Last name must contain letters only.');
    });

    test('rejects values with invalid special characters', () {
      expect(validator('Carter_'), 'Last name must contain letters only.');
    });

    test('rejects values shorter than minLength', () {
      expect(validator('A'), 'Last name must be at least 2 character long.');
    });

    test('rejects values longer than maxLength', () {
      expect(
        validator('A' * 31),
        'Last name may be at most 30 characters long.',
      );
    });

    test('rejects empty values', () {
      expect(validator(''), 'Last name is required.');
      expect(validator(null), 'Last name is required.');
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
