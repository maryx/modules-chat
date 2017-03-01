// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:models/user.dart';
import 'package:widgets/user.dart';
import 'package:util/time_util.dart';

import 'chat_bubble.dart';

/// UI Widget that represents a consecutive sequence of [ChatBubble]s by the
/// same user.
///
/// Like the [ChatBubble], the [ChatSection] also has an orientation
/// (left/right) depending on if the user is a sender/recipient.
///
/// The orientation for the children [ChatBubble]s should be the same as the
/// [ChatSection]
class ChatSection extends StatelessWidget{

  /// User of the given chat section
  final User user;

  /// List of chat bubbles to show inside the section
  final List<ChatBubble> chatBubbles;

  /// Orientation (left/right) of the chat section
  final ChatBubbleOrientation orientation;

  /// Timestamp for chat section
  final DateTime timestamp;

  /// Constructor
  ChatSection({
    Key key,
    @required this.user,
    @required this.chatBubbles,
    this.timestamp,
    ChatBubbleOrientation orientation,
  })
      : orientation = orientation ?? ChatBubbleOrientation.left,
      super(key: key) {
    assert(user != null);
    assert(chatBubbles != null);
    chatBubbles.forEach((ChatBubble bubble) {
      assert(bubble.orientation == orientation);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget alphatar = new Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: new Alphatar.fromUser(user: user),
    );
    Widget chatColumn = new Expanded(
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: orientation == ChatBubbleOrientation.left ?
            CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: chatBubbles,
      ),
    );

    // Order avatar & chat bubbles depending on orientation
    List<Widget> rowChildren;
    if(orientation == ChatBubbleOrientation.left) {
      rowChildren = <Widget>[
        alphatar,
        chatColumn,
      ];
    } else {
      rowChildren = <Widget>[
        chatColumn,
        alphatar,
      ];
    }
    Widget sectionContainer = new Container(
      margin: const EdgeInsets.only(bottom: 4.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: rowChildren,
      ),
    );

    // Add timestamp if it is given
    if(timestamp != null) {
      return new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: orientation == ChatBubbleOrientation.left ?
            CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: <Widget>[
          sectionContainer,
          new Container(
            margin: orientation == ChatBubbleOrientation.left ?
                const EdgeInsets.only(left: 50.0) :
                const EdgeInsets.only(right: 50.0),
            child: new Text(
              TimeUtil.relativeDisplayDate(date: timestamp),
              style: new TextStyle(
                fontSize: 12.0,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      );
    } else {
      return sectionContainer;
    }
  }
}
