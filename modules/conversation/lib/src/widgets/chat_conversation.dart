// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import 'chat_section.dart';
import 'message_input.dart';

/// UI Widget that represents a single chat thread
class ChatConversation extends StatefulWidget {
  /// List of [ChatSection]s to render
  ///
  /// TODO(dayang): Pass in the data model representing a chat thread
  /// once that is specified
  final List<ChatSection> chatSections;

  /// Title of thread
  final String title;

  /// Callback for when a new message is submitted
  final ValueChanged<String> onSubmitMessage;

  /// Optional [ScrollController] to be used in the [ListView]. The [ListView]
  /// is a reverse list, so the `0.0` scroll offset indicates the bottom end of
  /// the list.
  final ScrollController scrollController;

  /// Constructor
  ChatConversation({
    Key key,
    @required this.chatSections,
    this.title,
    this.onSubmitMessage,
    this.scrollController,
  })
      : super(key: key) {
    assert(this.chatSections != null);
  }

  @override
  _ChatConversationState createState() => new _ChatConversationState();
}

class _ChatConversationState extends State<ChatConversation> {
  final ScrollController _scrollController = new ScrollController();

  ScrollController get effectiveScrollController =>
      widget.scrollController ?? _scrollController;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return new Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        new Container(
          height: 56.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          alignment: FractionalOffset.centerLeft,
          decoration: new BoxDecoration(
            border: new Border(bottom: new BorderSide(color: Colors.grey[300])),
          ),
          child: new Text(
            widget.title ?? 'Chat',
            style: theme.textTheme.title,
          ),
        ),
        new Expanded(
          child: new Column(
            children: <Widget>[
              new Flexible(
                child: new Container(
                  padding: const EdgeInsets.all(8.0),
                  child: new ListView(
                    controller: effectiveScrollController,
                    reverse: true,
                    shrinkWrap: true,
                    children: widget.chatSections.reversed.toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        new MessageInput(
          onSubmitMessage: widget.onSubmitMessage,
        ),
      ],
    );
  }
}
