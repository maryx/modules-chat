// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:apps.modules.chat.agents.content_provider..chat_content_provider_dart_package/src/chat_message_transporter.dart';
import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart';
import 'package:meta/meta.dart';

/// A mock [ChatMessageTransporter] implementation for testing.
class MockChatMessageTransporter extends ChatMessageTransporter {
  @override
  Future<Null> initialize() async {}

  @override
  Future<Null> sendMessage({
    @required Conversation conversation,
    @required List<int> messageId,
    @required String type,
    @required String jsonPayload,
  }) async {}

  /// Pretends that a new message has arrived from another user and notify the
  /// client.
  Future<Null> mockReceiveMessage(
    @required Conversation conversation,
    @required Message message,
  ) async {
    if (this.onReceived != null) {
      await onReceived(conversation, message);
    }
  }
}
