// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart'
    as ccp;
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:models/user.dart';

import 'models.dart';
import 'widgets.dart';

void _log(String msg) {
  print('[chat_conversation_list_screen] $msg');
}

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
  List<Conversation> conversations = <Conversation>[];

  @override
  void initState() {
    super.initState();

    // Initiate the fetch.
    _log('Calling getConversations.');
    config.chatContentProvider
        .getConversations((List<ccp.Conversation> fidlConversations) {
      _log('getConversations callback.');
      setState(() {
        conversations =
            fidlConversations.map(_getConversationFromFidl).toList();
      });
    });
    _log('Called getConversations.');
  }

  Conversation _getConversationFromFidl(ccp.Conversation c) {
    // TODO(youngseokyoon): get the last message and fill in the info.
    return new Conversation(
      conversationId: c.conversationId,
      participants: c.participants.map(_getUserFromFidl).toList(),
      snippet: null,
      timestamp: null,
    );
  }

  User _getUserFromFidl(ccp.User u) {
    return new User(
      email: u.emailAddress,
      name: u.displayName,
      picture: u.profilePictureUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new ChatConversationList(
      conversations: conversations,
    );
  }
}
