// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:models/user.dart';

import 'chat_bubble.dart';
import 'chat_section.dart';
import 'message_input.dart';

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
      body:  new Stack(
        children: <Widget>[
          new Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: <Widget>[
             new ChatSection(
               user: new User(name: 'Coco', email: 'Coco@cute'),
               orientation: ChatBubbleOrientation.left,
               timestamp: new DateTime.now(),
               chatBubbles: <ChatBubble>[
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
                     'Is it me you\'re looking for?',
                     style: const TextStyle(color: Colors.white),
                   ),
                 ),
               ],
             ),
             new ChatSection(
               user: new User(name: 'Yoyo', email: 'Yoyo@cute'),
               orientation: ChatBubbleOrientation.right,
               timestamp: new DateTime.now(),
               chatBubbles: <ChatBubble>[
                 new ChatBubble(
                   backgroundColor: Colors.grey[200],
                   orientation: ChatBubbleOrientation.right,
                   child: new Text(
                     'Cause I wonder where you are...',
                   ),
                 ),
                 new ChatBubble(
                   backgroundColor: Colors.grey[200],
                   orientation: ChatBubbleOrientation.right,
                   child: new Text(
                     'and I wonder what you do',
                   ),
                 ),
               ],
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
         )
        ],
      ),
    );
  }
}
