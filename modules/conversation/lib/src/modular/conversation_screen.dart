// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

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
              sections: conversationModel.sections,
              onSubmitMessage: conversationModel.sendMessage,
              scrollController: conversationModel.scrollController,
            );
          },
        ),
      ),
    );
  }
}
