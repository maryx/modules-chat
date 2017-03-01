// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:models/user.dart';

import '../lib/src/widgets/chat_thread_list_item.dart';

void main() {
  testWidgets(
      'Test to see if tapping on a ChatThreadListItem will call the '
      'appropiate callback', (WidgetTester tester) async {
    Key chatThreadListItemKey = new UniqueKey();

    int taps = 0;

    await tester.pumpWidget(new Material(
      child: new ChatThreadListItem(
        key: chatThreadListItemKey,
        users: <User>[new User(name: 'Coco yang', email: 'Coco@cute')],
        onSelect: () {
          taps++;
        }
      ),
    ));

    expect(taps, 0);
    await tester.tap(find.byKey(chatThreadListItemKey));
    expect(taps, 1);
  });
}
