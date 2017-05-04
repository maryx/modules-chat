// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fixtures/fixtures.dart';

import '../models.dart';

/// Test fixtures for chat conversation models.
class ChatConversationFixtures extends Fixtures {
  /// Gets a randomly generated chat [Message].
  Message message({DateTime time, String sender}) {
    return new TextMessage(
      time: time ?? new DateTime.now(),
      sender: sender ?? _sender(),
      text: lorem.createSentence(),
    );
  }

  /// Gets a randomly generated chat [Section].
  Section section({
    String sender,
    int numMessages,
    bool shouldDisplayDateHeader,
    bool shouldDisplayLastMessageTime,
  }) {
    sender ??= _sender();
    numMessages ??= rng.nextInt(3) + 1;

    List<Message> messages = <Message>[];
    for (int i = 0; i < numMessages; ++i) {
      messages.add(message(sender: sender));
    }

    return new Section(
      messages: messages,
      shouldDisplayDateHeader: shouldDisplayDateHeader ?? rng.nextBool(),
      shouldDisplayLastMessageTime:
          shouldDisplayLastMessageTime ?? rng.nextBool(),
    );
  }

  String _sender() =>
      rng.nextBool() ? 'me' : name().replaceAll(' ', '.').toLowerCase();
}
