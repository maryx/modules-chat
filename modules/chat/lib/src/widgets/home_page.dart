// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'chat_bubble.dart';

/// MyHomePage widget.
class MyHomePage extends StatelessWidget {
  /// MyHomePage constructor.
  MyHomePage({Key key, this.title}) : super(key: key);

  /// MyHomePage title.
  final String title;

  @override
  Widget build(BuildContext buildContext) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(title),
      ),
      body: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new ChatBubble(
            orientation: ChatBubbleOrientation.left,
            child: new Text(
              'Hello',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          new ChatBubble(
            orientation: ChatBubbleOrientation.left,
            child: new Text(
              ' Is it me you\'re looking for?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
