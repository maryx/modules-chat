// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

const Radius _kBubbleBorderRadius = const Radius.circular(8.0);

/// The direction that the chat bubble is orientated
enum ChatBubbleOrientation {
  /// Chat bubble is on the left side of the screen
  left,
  /// Chat bubble is on the right side of the screen
  right,
}

/// UI Widget for a chat bubble
/// A [ChatBubble] has an orientation (left/right) usually based on who the
/// message belongs to (recipient/sender)
class ChatBubble extends StatelessWidget {

  /// Child widget to embed inside the ChatBubble
  final Widget child;

  /// Orientation of chat bubble
  /// Defaults to ChatBubbleOrientation.left
  final ChatBubbleOrientation orientation;

  /// Background color of chat bubble
  /// Defaults to the primary color of theme
  final Color backgroundColor;

  /// Constructor
  ChatBubble({
    Key key,
    ChatBubbleOrientation orientation,
    this.backgroundColor,
    @required this.child,
  }) : orientation = orientation ?? ChatBubbleOrientation.left,
      super(key: key) {
    assert(child != null);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    BorderRadius borderRadius;
    if(orientation == ChatBubbleOrientation.left) {
      borderRadius = const BorderRadius.only(
        bottomRight: _kBubbleBorderRadius,
        topLeft: _kBubbleBorderRadius,
        topRight: _kBubbleBorderRadius,
      );
    } else {
      borderRadius = const BorderRadius.only(
        bottomLeft: _kBubbleBorderRadius,
        topLeft: _kBubbleBorderRadius,
        topRight: _kBubbleBorderRadius,
      );
    }
    return new Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(2.0),
      decoration: new BoxDecoration(
        backgroundColor: backgroundColor ?? theme.primaryColor,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}
