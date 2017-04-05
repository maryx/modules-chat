// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:chat_conversation_list/models.dart';
import 'package:chat_conversation_list/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:models/user.dart';

void main() {
  testWidgets(
      'Test to see if tapping on the new chat FAB will call the '
      'appropriate callback', (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(new Material(
      child: new ChatConversationList(
        conversations: <Conversation>[],
        onNewConversation: () {
          taps++;
        },
      ),
    ));

    expect(taps, 0);
    await tester.tap(find.byType(FloatingActionButton));
    expect(taps, 1);
  });

  testWidgets(
      'Test to see if tapping on a conversation in the list calls the '
      'appropriate callback', (WidgetTester tester) async {
    List<int> taps = <int>[0, 0];

    await tester.pumpWidget(new Material(
      child: new ChatConversationList(
        conversations: <Conversation>[
          // TODO(youngseokyoon): add fixtures (SO-333)
          new Conversation(
            conversationId: const <int>[0],
            snippet: 'Snippet #1',
            participants: <User>[
              new User(name: 'Coco yang', email: 'Coco@cute')
            ],
          ),
          new Conversation(
            conversationId: const <int>[1],
            snippet: 'Snippet #2',
            participants: <User>[
              new User(name: 'Yoyo yang', email: 'Yoyo@cute')
            ],
          ),
        ],
        onSelectConversation: (Conversation c) => taps[c.conversationId[0]]++,
      ),
    ));

    expect(taps, orderedEquals(<int>[0, 0]));
    await tester.tap(find.text('Snippet #1'));
    expect(taps, orderedEquals(<int>[1, 0]));
    await tester.tap(find.text('Snippet #2'));
    expect(taps, orderedEquals(<int>[1, 1]));
  });
}
