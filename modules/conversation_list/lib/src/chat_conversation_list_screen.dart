// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart'
    as ccp;
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:models/user.dart';

import 'widgets.dart';

/// Top-level widget for the chat_conversation_list module.
class ChatConversationListScreen extends StatefulWidget {
  /// Creates a new instance of [ChatConversationListScreen].
  ChatConversationListScreen({
    Key key,
    @required this.chatContentProvider,
  }) {
    assert(chatContentProvider != null);
  }

  /// The [ccp.ChatContentProvider] interface.
  final ccp.ChatContentProvider chatContentProvider;

  @override
  _ChatConversationListScreenState createState() =>
      new _ChatConversationListScreenState();
}

class _ChatConversationListScreenState
    extends State<ChatConversationListScreen> {
  List<ChatThreadListItem> chatThreads = <ChatThreadListItem>[];

  @override
  void initState() {
    super.initState();

    // Initiate the fetch.
    config.chatContentProvider
        .getConversations((List<ccp.Conversation> conversations) {
      setState(() {
        chatThreads = conversations
            .map((ccp.Conversation c) => new ChatThreadListItem(
                  users: c.participants
                      .map((ccp.User u) => new User(
                            email: u.emailAddress,
                            name: u.displayName,
                            picture: u.profilePictureUrl,
                          ))
                      .toList(),
                  onSelect: () => print('onSelect called'),
                  snippet: null,
                  timestamp: null,
                ))
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new ChatThreadList(chatThreads: chatThreads);
  }
}
