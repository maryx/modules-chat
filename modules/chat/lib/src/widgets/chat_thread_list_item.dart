// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:models/user.dart';
import 'package:util/time_util.dart';

import 'chat_group_avatar.dart';

/// UI Widget that represents a single chat thread when viewing many chat
/// threads in a list.
class ChatThreadListItem extends StatelessWidget {

  /// Text snippet representing the chat. This usually is the last message in
  /// the given thread.
  final String snippet;

  /// Users that are part of the chat thread
  final List<User> users;

  /// Timestamp to show when the most recent activity happened
  final DateTime timestamp;

  /// Callback fired when this item is selected
  final VoidCallback onSelect;

  /// Constructor
  ChatThreadListItem({
    Key key,
    @required this.users,
    this.onSelect,
    this.snippet,
    this.timestamp,
  }) : super(key: key) {
    assert(users != null);
    assert(users.isNotEmpty);
  }

  String get _userNames => users.map((User user) => user.name).toList()
      .join(', ');

  @override
  Widget build(BuildContext context) {
    return new ListItem(
      leading: new ChatGroupAvatar(
        users: users,
      ),
      title: new Text(
        _userNames,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: new Text(
        snippet ?? '',
        overflow: TextOverflow.ellipsis,
      ),
      trailing: new Text(timestamp != null ?
        TimeUtil.relativeDisplayDate(date: timestamp) : '',
        style: new TextStyle(
          color: Colors.grey[500],
          fontSize: 12.0,
        ),
      ),
      onTap: () => onSelect?.call(),
    );
  }
}
