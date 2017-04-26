// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:lib.widgets/widgets.dart';
import 'package:meta/meta.dart';
import 'package:models/user.dart';

import 'constants.dart';

const double _kSizeRatio = 0.80;
const double _kBorderSize = 2.0;

/// UI Widget that shows a condensed view of a group of avatars
/// The avatar of the first two users will be shown
///
/// The list of users should not be empty
class ChatGroupAvatar extends StatelessWidget {
  /// List of users to represent as a group
  final List<User> users;

  /// Size of group avatar, defaults to 40.0
  final double size;

  /// Indicates whether this conversation is currently selected or not.
  final bool selected;

  /// Constructor
  ChatGroupAvatar({
    Key key,
    @required this.users,
    this.size: 40.0,
    bool selected,
  })
      : selected = selected ?? false,
        super(key: key) {
    assert(users != null);
    assert(users.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    if (users.length <= 0) {
      return new Offstage();
    } else if (users.length == 1) {
      return new Alphatar.fromNameAndUrl(
        name: users[0].name,
        avatarUrl: users[0].picture,
        size: size,
      );
    } else {
      return new Container(
        width: size,
        height: size,
        child: new Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            new Positioned(
              right: 0.0,
              top: 0.0,
              child: new Container(
                child: new Alphatar.fromNameAndUrl(
                  name: users[1].name,
                  avatarUrl: users[1].picture,
                  size: size * _kSizeRatio,
                ),
              ),
            ),
            new Positioned(
              left: -_kBorderSize,
              bottom: -_kBorderSize,
              child: new Container(
                child: new Alphatar.fromNameAndUrl(
                  name: users[0].name,
                  avatarUrl: users[0].picture,
                  size: size * _kSizeRatio,
                ),
                decoration: new BoxDecoration(
                  border: new Border.all(
                    // TODO(youngseokyoon): make it look better with InkWell
                    // https://fuchsia.atlassian.net/browse/SO-353
                    color: selected ? kSelectedBgColor : Colors.white,
                    width: _kBorderSize,
                  ),
                  borderRadius: new BorderRadius.circular(size),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
