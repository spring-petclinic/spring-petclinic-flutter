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

typedef StringValidator = String? Function(String? value);

class AppValidators {
  static const int petMaximumAgeYears = 50;

  static StringValidator compose(List<StringValidator> validators) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }

  static StringValidator required(String fieldName) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required.';
      }
      return null;
    };
  }

  static StringValidator lettersOnly(
    String fieldName, {
    required int minLength,
    required int maxLength,
  }) {
    final pattern = RegExp(r'^[A-Za-z]+$');
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) {
        return '$fieldName is required.';
      }
      if (text.length < minLength) {
        return '$fieldName must be at least $minLength character long.';
      }
      if (text.length > maxLength) {
        return '$fieldName may be at most $maxLength characters long.';
      }
      if (!pattern.hasMatch(text)) {
        return '$fieldName must contain letters only.';
      }
      return null;
    };
  }

  static StringValidator digitsOnly(
    String fieldName, {
    required int minLength,
    required int maxLength,
  }) {
    final pattern = RegExp(r'^[0-9]+$');
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) {
        return '$fieldName is required.';
      }
      if (text.length < minLength) {
        return '$fieldName must be at least $minLength digit long.';
      }
      if (text.length > maxLength) {
        return '$fieldName may be at most $maxLength digits long.';
      }
      if (!pattern.hasMatch(text)) {
        return '$fieldName must contain digits only.';
      }
      return null;
    };
  }

  static StringValidator exactDigits(String fieldName, {required int length}) {
    final pattern = RegExp(r'^[0-9]+$');
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) {
        return '$fieldName is required.';
      }
      if (!pattern.hasMatch(text)) {
        return '$fieldName must contain digits only.';
      }
      if (text.length != length) {
        return '$fieldName must be exactly $length digits long.';
      }
      return null;
    };
  }

  static StringValidator plainText(
    String fieldName, {
    required int minLength,
    required int maxLength,
  }) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) {
        return '$fieldName is required.';
      }
      if (text.length < minLength) {
        return '$fieldName must be at least $minLength character long.';
      }
      if (text.length > maxLength) {
        return '$fieldName may be at most $maxLength characters long.';
      }
      return null;
    };
  }

  static StringValidator alphaNumericStart(
    String fieldName, {
    required int minLength,
    required int maxLength,
  }) {
    final pattern = RegExp(r'^[A-Za-z0-9].*$');
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) {
        return '$fieldName is required.';
      }
      if (text.length < minLength) {
        return '$fieldName must be at least $minLength character long.';
      }
      if (text.length > maxLength) {
        return '$fieldName may be at most $maxLength characters long.';
      }
      if (!pattern.hasMatch(text)) {
        return '$fieldName must start with a letter or digit.';
      }
      return null;
    };
  }

  static StringValidator petBirthDate(String fieldName, {DateTime? today}) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) {
        return '$fieldName is required.';
      }

      final birthDate = _parseApiDate(text);
      if (birthDate == null) {
        return '$fieldName must be a valid date.';
      }

      final currentDate = _dateOnly(today ?? DateTime.now());
      if (birthDate.isAfter(currentDate)) {
        return '$fieldName cannot be in the future.';
      }

      if (birthDate.isBefore(minimumPetBirthDate(currentDate))) {
        return '$fieldName cannot be older than $petMaximumAgeYears years.';
      }

      return null;
    };
  }

  static DateTime minimumPetBirthDate(DateTime today) {
    final currentDate = _dateOnly(today);
    final targetYear = currentDate.year - petMaximumAgeYears;
    final lastDayOfTargetMonth = DateTime(
      targetYear,
      currentDate.month + 1,
      0,
    ).day;
    final targetDay = currentDate.day > lastDayOfTargetMonth
        ? lastDayOfTargetMonth
        : currentDate.day;
    return DateTime(targetYear, currentDate.month, targetDay);
  }

  static DateTime? _parseApiDate(String text) {
    try {
      final parsed = DateTime.parse(text);
      final dateOnly = _dateOnly(parsed);
      final formatted =
          '${dateOnly.year.toString().padLeft(4, '0')}-'
          '${dateOnly.month.toString().padLeft(2, '0')}-'
          '${dateOnly.day.toString().padLeft(2, '0')}';
      return formatted == text ? dateOnly : null;
    } catch (_) {
      return null;
    }
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
