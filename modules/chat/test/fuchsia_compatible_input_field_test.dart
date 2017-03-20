// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:chat/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'FuchsiaCompatibleInputField should use a RawKeyboardInputField when the '
      'current platform is Fuchsia.', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(platform: TargetPlatform.fuchsia),
        child: new Material(
          child: new FuchsiaCompatibleInputField(),
        ),
      ),
    );

    expect(tester.widget(find.byType(RawKeyboardInputField)), isNotNull);
  });

  testWidgets(
      'FuchsiaCompatibleInputField should use a normal InputField when the '
      'current platform is not Fuchsia.', (WidgetTester tester) async {
    List<TargetPlatform> platforms = <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
    ];

    for (TargetPlatform platform in platforms) {
      await tester.pumpWidget(
        new Theme(
          data: new ThemeData(platform: platform),
          child: new Material(
            child: new FuchsiaCompatibleInputField(),
          ),
        ),
      );

      expect(tester.widget(find.byType(InputField)), isNotNull);
    }
  });

  testWidgets(
      'FuchsiaCompatibleInputField should use a RawKeyboardInputField when the '
      'current platform is Fuchsia.', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(platform: TargetPlatform.fuchsia),
        child: new Material(
          child: new FuchsiaCompatibleInputField(),
        ),
      ),
    );

    expect(tester.widget(find.byType(RawKeyboardInputField)), isNotNull);
  });
}
