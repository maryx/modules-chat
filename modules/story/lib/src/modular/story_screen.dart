// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

import 'story_module_model.dart';

/// Top-level widget for the chat_story module.
class ChatStoryScreen extends StatelessWidget {
  /// Creates a new instance of [ChatStoryScreen].
  ChatStoryScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(primarySwatch: Colors.purple),
      home: new Material(
        child: new ScopedModelDescendant<ChatStoryModuleModel>(
          builder: (
            BuildContext context,
            Widget child,
            ChatStoryModuleModel storyModel,
          ) {
            return _buildChildLayout(context, storyModel);
          },
        ),
      ),
    );
  }

  Widget _buildChildLayout(
    BuildContext context,
    ChatStoryModuleModel storyModel,
  ) {
    return new Row(
      children: <Widget>[
        new Expanded(
          flex: 1,
          child: new Container(
            decoration: new BoxDecoration(
              border: new Border(
                right: new BorderSide(color: Colors.grey[300]),
              ),
            ),
            child: storyModel.conversationListConnection != null
                ? new ChildView(
                    connection: storyModel.conversationListConnection)
                : new Container(),
          ),
        ),
        new Expanded(
          flex: 2,
          child: storyModel.conversationConnection != null
              ? new ChildView(connection: storyModel.conversationConnection)
              : new Container(),
        )
      ],
    );
  }
}
