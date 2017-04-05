// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'chat_section.dart';
import 'message_input.dart';

/// UI Widget that represents a single chat thread
class ChatConversation extends StatelessWidget {
  /// List of [ChatSection]s to render
  ///
  /// TODO(dayang): Pass in the data model representing a chat thread
  /// once that is specified
  final List<ChatSection> chatSections;

  /// Title of thread
  final String title;

  /// Constructor
  ChatConversation({
    Key key,
    @required this.chatSections,
    this.title,
  })
      : super(key: key) {
    assert(this.chatSections != null);
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
                border:
                    new Border(bottom: new BorderSide(color: Colors.grey[300])),
              ),
              child: new Text(
                title ?? 'Chat',
                style: theme.textTheme.title,
              ),
            ),
            new Container(
              padding: const EdgeInsets.all(8.0),
              child: new ListView(
                shrinkWrap: true,
                children: chatSections,
              ),
            ),
          ],
        ),
        new Positioned(
          bottom: 0.0,
          right: 0.0,
          left: 0.0,
          child: new MessageInput(
            onSubmitMessage: (String msg) => print('Message: $msg'),
          ),
        ),
      ],
    );
  }
}
