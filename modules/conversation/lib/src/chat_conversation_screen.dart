// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart'
    as ccp;
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:models/user.dart';

import 'widgets.dart';

void _log(String msg) {
  print('[chat_conversation_screen] $msg');
}

/// Top-level widget for the chat_conversation module.
class ChatConversationScreen extends StatefulWidget {
  /// Creates a new instance of [ChatConversationScreen].
  ChatConversationScreen({
    Key key,
    @required this.chatContentProvider,
    this.conversationId,
  }) {
    assert(chatContentProvider != null);
  }

  /// The [ccp.ChatContentProvider] interface.
  final ccp.ChatContentProvider chatContentProvider;

  /// The current conversation id.
  ///
  /// Ideally, this value should be obtained from the Link.
  final String conversationId;

  @override
  _ChatConversationScreenState createState() =>
      new _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  List<ChatSection> chatSections = <ChatSection>[];

  @override
  void initState() {
    super.initState();

    // Initiate the fetch.
    _log('Calling getMessageHistory');
    config.chatContentProvider.getMessageHistory(
      config.conversationId?.codeUnits ?? '',
      (List<ccp.Message> messages) {
        _log('getMessageHistory callback.');
        setState(() {
          chatSections = messages
              .map((ccp.Message message) => new ChatSection(
                    user: new User(
                      email: message.sender,
                      name: message.sender,
                    ),
                    chatBubbles: <ChatBubble>[
                      new ChatBubble(child: new Text(message.jsonPayload)),
                    ],
                  ))
              .toList();
        });
      },
    );
    _log('Called getMessageHistory');
  }

  @override
  Widget build(BuildContext context) {
    return new ChatThread(chatSections: chatSections);
  }
}
