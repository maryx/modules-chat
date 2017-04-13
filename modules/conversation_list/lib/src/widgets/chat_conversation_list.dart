// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../models/conversation.dart';
import 'chat_conversation_list_item.dart';

/// Callback function signature for an action on a conversation
typedef void ConversationActionCallback(Conversation message);

/// UI Widget that represents a list of chat conversations
class ChatConversationList extends StatelessWidget {
  static final ListEquality<int> _intListEquality = const ListEquality<int>();

  /// List of [Conversation]s to render.
  final List<Conversation> conversations;

  /// Callback for when the new chat FAB is pressed.
  final VoidCallback onNewConversation;

  /// Callback for when a conversation in the list is tapped.
  final ConversationActionCallback onSelectConversation;

  /// Indicates the conversation id of the selected conversation. Can be null.
  final List<int> selectedId;

  /// Constructor
  ChatConversationList({
    Key key,
    @required this.conversations,
    this.onNewConversation,
    this.onSelectConversation,
    this.selectedId,
  })
      : super(key: key) {
    assert(this.conversations != null);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return new Stack(
      children: <Widget>[
        new Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Container(
              height: 56.0,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: FractionalOffset.centerLeft,
              decoration: new BoxDecoration(
                border: new Border(
                  bottom: new BorderSide(color: Colors.grey[300]),
                ),
              ),
              child: new Text(
                'Chat',
                style: theme.textTheme.title,
              ),
            ),
            new Expanded(
              flex: 1,
              child: new ListView(
                shrinkWrap: true,
                children: conversations
                    .map(
                      (Conversation c) => new ChatConversationListItem(
                          conversation: c,
                          onSelect: () => onSelectConversation?.call(c),
                          selected: _intListEquality.equals(
                            selectedId,
                            c.conversationId,
                          )),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
        new Positioned(
          bottom: 16.0,
          right: 16.0,
          child: new FloatingActionButton(
            child: new Icon(Icons.add),
            onPressed: () => onNewConversation?.call(),
          ),
        ),
      ],
    );
  }
}
