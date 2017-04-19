// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart'
    as chat_fidl;
import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';
import 'package:models/user.dart';

import '../widgets.dart';
import 'conversation_module_model.dart';

/// Top-level widget for the chat_conversation module.
class ChatConversationScreen extends StatelessWidget {
  /// Creates a new instance of [ChatConversationScreen].
  ChatConversationScreen({Key key}) : super(key: key);

  static int _compareMessages(chat_fidl.Message m1, chat_fidl.Message m2) {
    if (m1.timestamp < m2.timestamp) return -1;
    if (m1.timestamp > m2.timestamp) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(primarySwatch: Colors.purple),
      home: new Material(
        child: new ScopedModelDescendant<ChatConversationModuleModel>(
          builder: (
            BuildContext context,
            Widget child,
            ChatConversationModuleModel conversationModel,
          ) {
            List<chat_fidl.Message> sorted = conversationModel.messages == null
                ? const <chat_fidl.Message>[]
                : (new List<chat_fidl.Message>.from(conversationModel.messages)
                  ..sort(_compareMessages));

            return new ChatConversation(
              chatSections: sorted.map(_buildSectionFromMessage).toList(),
              onSubmitMessage: conversationModel.sendMessage,
              scrollController: conversationModel.scrollController,
            );
          },
        ),
      ),
    );
  }

  ChatSection _buildSectionFromMessage(chat_fidl.Message message) {
    ChatBubbleOrientation orientation = message.sender == 'me'
        ? ChatBubbleOrientation.right
        : ChatBubbleOrientation.left;

    return new ChatSection(
      orientation: orientation,
      user: new User(
        email: message.sender,
        name: message.sender,
      ),
      chatBubbles: <ChatBubble>[
        new ChatBubble(
          child: new Text(message.jsonPayload),
          orientation: orientation,
        ),
      ],
    );
  }
}
