// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'chat_thread_list_item.dart';

/// UI Widget that represents a list of chat threads
class ChatThreadList extends StatelessWidget {
  /// List of [ChatThreadListItem]s to render
  ///
  /// TODO(dayang): Pass in the data model representing a chat thread
  /// once that is specified
  final List<ChatThreadListItem> chatThreads;

  /// Callback for when the new chat FAB is pressed
  final VoidCallback onNewChat;

  /// Constructor
  ChatThreadList({
    Key key,
    @required this.chatThreads,
    this.onNewChat,
  })
      : super(key: key) {
    assert(this.chatThreads != null);
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
            new ListView(
              shrinkWrap: true,
              children: chatThreads,
            ),
          ],
        ),
        new Positioned(
          bottom: 16.0,
          right: 16.0,
          child: new FloatingActionButton(
            child: new Icon(Icons.add),
            onPressed: () => onNewChat?.call(),
          ),
        ),
      ],
    );
  }
}
