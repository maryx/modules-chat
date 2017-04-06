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
            return new ChatConversation(
              chatSections: conversationModel.messages == null
                  ? const <ChatSection>[]
                  : conversationModel.messages
                      .map(_buildSectionFromMessage)
                      .toList(),
            );
          },
        ),
      ),
    );
  }

  ChatSection _buildSectionFromMessage(chat_fidl.Message message) {
    return new ChatSection(
      user: new User(
        email: message.sender,
        name: message.sender,
      ),
      chatBubbles: <ChatBubble>[
        new ChatBubble(child: new Text(message.jsonPayload)),
      ],
    );
  }
}
