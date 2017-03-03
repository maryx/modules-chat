// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:models/user.dart';

import 'chat_bubble.dart';
import 'chat_section.dart';
import 'chat_thread.dart';
import 'chat_thread_list.dart';
import 'chat_thread_list_item.dart';

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
      body: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Expanded(
            flex: 1,
            child: new Container(
              decoration: new BoxDecoration(
                border: new Border(
                  right: new BorderSide(color: Colors.grey[300]),
                ),
              ),
              child: new ChatThreadList(
                chatThreads: <ChatThreadListItem>[
                  new ChatThreadListItem(
                    users: <User>[
                      new User(
                        name: 'Coco',
                        email: 'Coco@cute',
                        picture:
                            'https://github.com/dvdwasibi/DogsOfFuchsia/blob/master/coco.jpg?raw=true',
                      ),
                      new User(
                        name: 'Yoyo',
                        email: 'Yoyo@cute',
                        picture:
                            'https://github.com/dvdwasibi/DogsOfFuchsia/blob/master/yoyo.jpg?raw=true',
                      ),
                    ],
                    snippet: 'Hello fellow puppers',
                    timestamp: new DateTime.now(),
                  ),
                  new ChatThreadListItem(
                    users: <User>[
                      new User(
                        name: 'Coco',
                        email: 'Coco@cute',
                        picture:
                            'https://github.com/dvdwasibi/DogsOfFuchsia/blob/master/coco.jpg?raw=true',
                      ),
                    ],
                    snippet: 'Toasters gonna toast',
                    timestamp: new DateTime.now(),
                  ),
                ],
              ),
            ),
          ),
          new Expanded(
            flex: 2,
            child: new ChatThread(
              chatSections: <ChatSection>[
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
              title: 'Hello',
            ),
          ),
        ],
      ),
    );
  }
}
