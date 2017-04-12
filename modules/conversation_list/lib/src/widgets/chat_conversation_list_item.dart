// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:models/user.dart';
import 'package:util/time_util.dart';

import '../models/conversation.dart';
import 'chat_group_avatar.dart';
import 'constants.dart';

/// UI Widget that represents a single chat conversation when viewing many chat
/// conversations in a list.
class ChatConversationListItem extends StatelessWidget {
  /// Conversation data model.
  final Conversation conversation;

  /// Callback fired when this item is selected.
  final VoidCallback onSelect;

  /// Indicates whether this conversation is currently selected or not.
  final bool selected;

  /// Constructor
  ChatConversationListItem({
    Key key,
    @required this.conversation,
    this.onSelect,
    bool selected,
  })
      : selected = selected ?? false,
        super(key: key) {
    assert(conversation != null);
    assert(conversation.participants != null);
  }

  String get _participantNames => conversation.participants
      .map((User user) => user.name ?? user.email)
      .toList()
      .join(', ');

  @override
  Widget build(BuildContext context) {
    return new Material(
      color: selected ? kSelectedBgColor : Colors.white,
      child: new ListTile(
        leading: new ChatGroupAvatar(
          users: conversation.participants,
          selected: selected,
        ),
        title: new Text(
          _participantNames,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: new Text(
          conversation.snippet ?? '',
          overflow: TextOverflow.ellipsis,
        ),
        trailing: new Text(
          conversation.timestamp != null
              ? TimeUtil.relativeDisplayDate(date: conversation.timestamp)
              : '',
          style: new TextStyle(
            color: Colors.grey[500],
            fontSize: 12.0,
          ),
        ),
        onTap: () => onSelect?.call(),
      ),
    );
  }
}
