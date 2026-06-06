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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spring_petclinic_flutter/features/owners/owner.dart';
import 'package:spring_petclinic_flutter/features/owners/owner_list_screen.dart';
import 'package:spring_petclinic_flutter/features/owners/owner_page.dart';
import 'package:spring_petclinic_flutter/features/owners/owner_service.dart';

class FakeOwnerService extends OwnerService {
  FakeOwnerService({this.owners = const [], this.error});

  final List<Owner> owners;
  final Object? error;

  @override
  Future<OwnerPage> listOwnersPage({
    String? lastName,
    required int page,
    required int size,
  }) async {
    if (error != null) {
      throw error!;
    }
    return OwnerPage(
      content: List<Owner>.unmodifiable(owners),
      page: page,
      size: size,
      totalElements: owners.length,
      totalPages: owners.isEmpty ? 0 : 1,
    );
  }
}

void main() {
  void configureLargeSurface(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1400, 1000);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
  }

  void configureShortLandscapeSurface(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(740, 260);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
  }

  testWidgets('places Add Owner below the owners table on the left', (
    WidgetTester tester,
  ) async {
    configureLargeSurface(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: OwnerListScreen(
          ownerService: FakeOwnerService(
            owners: const [
              Owner(
                id: 1,
                firstName: 'George',
                lastName: 'Franklin',
                address: '110 W. Liberty St.',
                city: 'Madison',
                telephone: '6085551023',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addOwnerButton = find.widgetWithText(FilledButton, 'Add Owner');
    final ownerName = find.text('George Franklin');

    expect(addOwnerButton, findsOneWidget);
    expect(ownerName, findsOneWidget);
    expect(tester.getTopLeft(addOwnerButton).dx, lessThan(220));
    expect(
      tester.getTopLeft(addOwnerButton).dy,
      greaterThan(tester.getBottomLeft(ownerName).dy),
    );
  });

  testWidgets(
    'renders owner list without overflow on short landscape screens',
    (WidgetTester tester) async {
      configureShortLandscapeSurface(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: OwnerListScreen(
            ownerService: FakeOwnerService(
              owners: const [
                Owner(
                  id: 1,
                  firstName: 'Harold',
                  lastName: 'Davis',
                  address: '563 Friendly St.',
                  city: 'Windsor',
                  telephone: '6085553198',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Owners'), findsOneWidget);
      expect(find.text('Harold Davis'), findsOneWidget);
      expect(
        find.text('Spring Petclinic Flutter Sample Application'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders owner list error state without overflow on short landscape screens',
    (WidgetTester tester) async {
      configureShortLandscapeSurface(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: OwnerListScreen(
            ownerService: FakeOwnerService(error: 'Network error'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Owners'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
