// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:chat_story/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'Test to see if tapping on the new chat FAB will call the '
      'appropriate callback', (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(new Material(
      child: new ChatThreadList(
        chatThreads: <ChatThreadListItem>[],
        onNewChat: () {
          taps++;
        },
      ),
    ));

    expect(taps, 0);
    await tester.tap(find.byType(FloatingActionButton));
    expect(taps, 1);
  });
}
