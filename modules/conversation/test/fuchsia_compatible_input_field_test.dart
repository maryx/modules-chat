// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:chat_conversation/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'FuchsiaCompatibleTextField should use a RawKeyboardTextField when the '
      'current platform is Fuchsia.', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(platform: TargetPlatform.fuchsia),
        child: new Material(
          child: new FuchsiaCompatibleTextField(),
        ),
      ),
    );

    expect(tester.widget(find.byType(RawKeyboardTextField)), isNotNull);
  });

  testWidgets(
      'FuchsiaCompatibleTextField should use a normal TextField when the '
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
            child: new FuchsiaCompatibleTextField(),
          ),
        ),
      );

      expect(tester.widget(find.byType(TextField)), isNotNull);
    }
  });

  testWidgets(
      'FuchsiaCompatibleTextField should use a RawKeyboardTextField when the '
      'current platform is Fuchsia.', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(platform: TargetPlatform.fuchsia),
        child: new Material(
          child: new FuchsiaCompatibleTextField(),
        ),
      ),
    );

    expect(tester.widget(find.byType(RawKeyboardTextField)), isNotNull);
  });
}
