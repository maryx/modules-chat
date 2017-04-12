// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

import '../models.dart';
import '../widgets.dart';
import 'conversation_list_module_model.dart';

/// Top-level widget for the chat_conversation_list module.
class ChatConversationListScreen extends StatelessWidget {
  /// Creates a new instance of [ChatConversationListScreen].
  ChatConversationListScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(primarySwatch: Colors.purple),
      home: new Material(
        child: new ScopedModelDescendant<ChatConversationListModuleModel>(
          builder: (
            BuildContext context,
            Widget child,
            ChatConversationListModuleModel conversationListModel,
          ) {
            return new ChatConversationList(
              conversations: conversationListModel.conversations == null
                  ? <Conversation>[]
                  : conversationListModel.conversations,
              onSelectConversation: (Conversation c) =>
                  conversationListModel.setConversationId(c.conversationId),
              selectedId: conversationListModel.conversationId,
            );
          },
        ),
      ),
    );
  }
}
