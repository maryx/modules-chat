// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:chat_conversation/fixtures.dart';
import 'package:chat_conversation/models.dart';
import 'package:test/test.dart';

void main() {
  test('section extraction - null to null', () {
    List<Section> sections = createSectionsFromMessages(null);
    expect(sections, isNull);
  });

  test('section extraction - empty list to empty list', () {
    List<Section> sections = createSectionsFromMessages(const <Message>[]);
    expect(sections, isNotNull);
    expect(sections, isEmpty);
  });

  test('section extraction - single message', () {
    ChatConversationFixtures fixtures = new ChatConversationFixtures();

    List<Message> messages = <Message>[fixtures.message()];
    List<Section> sections = createSectionsFromMessages(messages);

    expect(sections, isNotNull);
    expect(sections, hasLength(1));
    expect(sections[0].firstMessageTime, equals(messages[0].time));
    expect(sections[0].lastMessageTime, equals(messages[0].time));
    expect(sections[0].shouldDisplayDateHeader, isTrue);
    expect(sections[0].shouldDisplayLastMessageTime, isTrue);
  });

  test('section extraction - multiple messages from multiple users', () {
    ChatConversationFixtures fixtures = new ChatConversationFixtures();

    String alice = 'alice@example.com';
    List<Message> messages = <Message>[];

    for (int i = 0; i < 3; ++i) {
      messages.add(fixtures.message(
        time: DateTime.parse('2017-05-04 09:00:0$i'),
        sender: alice,
      ));
    }

    for (int i = 0; i < 3; ++i) {
      messages.add(fixtures.message(
        time: DateTime.parse('2017-05-04 09:00:0${i+3}'),
        sender: 'me',
      ));
    }

    messages.add(fixtures.message(
      time: DateTime.parse('2017-05-04 09:01:00'),
      sender: alice,
    ));

    messages.add(fixtures.message(
      time: DateTime.parse('2017-05-04 11:00:00'),
      sender: alice,
    ));

    messages.add(fixtures.message(
      time: DateTime.parse('2017-05-05 09:00:00'),
      sender: 'me',
    ));

    List<Section> sections = createSectionsFromMessages(messages);

    expect(sections, isNotNull);
    expect(sections, hasLength(5));

    expect(
      sections[0].firstMessageTime,
      equals(DateTime.parse('2017-05-04 09:00:00')),
    );
    expect(
      sections[0].lastMessageTime,
      equals(DateTime.parse('2017-05-04 09:00:02')),
    );
    expect(sections[0].messages, hasLength(3));
    expect(sections[0].sender, equals(alice));
    expect(sections[0].isMyMessage, isFalse);
    expect(sections[0].shouldDisplayDateHeader, isTrue);
    expect(sections[0].shouldDisplayLastMessageTime, isFalse);

    expect(
      sections[1].firstMessageTime,
      equals(DateTime.parse('2017-05-04 09:00:03')),
    );
    expect(
      sections[1].lastMessageTime,
      equals(DateTime.parse('2017-05-04 09:00:05')),
    );
    expect(sections[1].messages, hasLength(3));
    expect(sections[1].sender, equals('me'));
    expect(sections[1].isMyMessage, isTrue);
    expect(sections[1].shouldDisplayDateHeader, isFalse);
    expect(sections[1].shouldDisplayLastMessageTime, isFalse);

    expect(
      sections[2].firstMessageTime,
      equals(DateTime.parse('2017-05-04 09:01:00')),
    );
    expect(
      sections[2].lastMessageTime,
      equals(DateTime.parse('2017-05-04 09:01:00')),
    );
    expect(sections[2].messages, hasLength(1));
    expect(sections[2].sender, equals(alice));
    expect(sections[2].isMyMessage, isFalse);
    expect(sections[2].shouldDisplayDateHeader, isFalse);
    expect(sections[2].shouldDisplayLastMessageTime, isTrue);

    expect(
      sections[3].firstMessageTime,
      equals(DateTime.parse('2017-05-04 11:00:00')),
    );
    expect(
      sections[3].lastMessageTime,
      equals(DateTime.parse('2017-05-04 11:00:00')),
    );
    expect(sections[3].messages, hasLength(1));
    expect(sections[3].sender, equals(alice));
    expect(sections[3].isMyMessage, isFalse);
    expect(sections[3].shouldDisplayDateHeader, isFalse);
    expect(sections[3].shouldDisplayLastMessageTime, isTrue);

    expect(
      sections[4].firstMessageTime,
      equals(DateTime.parse('2017-05-05 09:00:00')),
    );
    expect(
      sections[4].lastMessageTime,
      equals(DateTime.parse('2017-05-05 09:00:00')),
    );
    expect(sections[4].messages, hasLength(1));
    expect(sections[4].sender, equals('me'));
    expect(sections[4].isMyMessage, isTrue);
    expect(sections[4].shouldDisplayDateHeader, isTrue);
    expect(sections[4].shouldDisplayLastMessageTime, isTrue);
  });
}
