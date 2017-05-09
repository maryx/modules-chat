// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lib.widgets/widgets.dart';
import 'package:meta/meta.dart';
import 'package:util/time_util.dart';

import '../models.dart';
import 'chat_bubble.dart';

/// UI Widget that represents a consecutive sequence of [ChatBubble]s by the
/// same user.
///
/// Like the [ChatBubble], the [ChatSection] also has an orientation
/// (left/right) depending on if the user is a sender/recipient.
///
/// The orientation for the children [ChatBubble]s should be the same as the
/// [ChatSection]
class ChatSection extends StatelessWidget {
  /// Chat [Section] model
  final Section section;

  /// [DateFormat] to be used in the date header.
  static final DateFormat _kDateHeaderFormat = new DateFormat.yMMMMd();

  /// Constructor
  ChatSection({
    Key key,
    @required this.section,
  })
      : super(key: key) {
    assert(section != null);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    Widget chatColumn = _buildBubbles(theme, section.messages);

    // Order avatar & chat bubbles depending on orientation
    List<Widget> rowChildren;
    if (section.isMyMessage) {
      rowChildren = <Widget>[chatColumn];
    } else {
      Widget alphatar = new Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: new Alphatar.fromName(name: section.sender),
      );
      rowChildren = <Widget>[alphatar, chatColumn];
    }

    Widget result = new Container(
      margin: const EdgeInsets.only(bottom: 4.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: rowChildren,
      ),
    );

    // Add timestamp if it should be displayed.
    if (section.shouldDisplayLastMessageTime) {
      result = new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: section.isMyMessage
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: <Widget>[
          result,
          new Container(
            margin: section.isMyMessage
                ? const EdgeInsets.only(bottom: 16.0)
                : const EdgeInsets.only(left: 50.0, bottom: 16.0),
            child: new Text(
              TimeUtil.relativeDisplayDate(
                date: section.lastMessageTime,
                alwaysIncludeTime: true,
              ),
              style: new TextStyle(
                fontSize: 12.0,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      );
    }

    // Add date header if needed.
    if (section.shouldDisplayDateHeader) {
      result = new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _buildDateHeader(theme),
          result,
        ],
      );
    }

    return result;
  }

  Widget _buildDateHeader(ThemeData theme) {
    String dateText =
        _kDateHeaderFormat.format(section.firstMessageTime).toUpperCase();

    return new Container(
      padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
      child: new Text(
        '—  $dateText  —',
        style: new TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildBubbles(ThemeData theme, List<Message> messages) {
    Color backgroundColor =
        section.isMyMessage ? Colors.grey[300] : theme.textSelectionHandleColor;

    ChatBubbleOrientation orientation = section.isMyMessage
        ? ChatBubbleOrientation.right
        : ChatBubbleOrientation.left;

    return new Expanded(
      child: new DefaultTextStyle(
        style: section.isMyMessage
            ? theme.textTheme.body1
            : theme.primaryTextTheme.body1,
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: section.isMyMessage
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: section.messages
              .map((Message message) => new ChatBubble(
                    child: message.buildWidget(),
                    orientation: orientation,
                    backgroundColor: backgroundColor,
                    fillBubble: message.fillBubble,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
