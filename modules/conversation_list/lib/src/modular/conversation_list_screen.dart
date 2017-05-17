// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:lib.widgets/model.dart';

import '../models.dart';
import '../widgets.dart';
import 'conversation_list_module_model.dart';

/// Top-level widget for the chat_conversation_list module.
class ChatConversationListScreen extends StatefulWidget {
  /// Creates a new instance of [ChatConversationListScreen].
  ChatConversationListScreen({Key key}) : super(key: key);

  @override
  _ChatConversationListScreenState createState() =>
      new _ChatConversationListScreenState();
}

class _ChatConversationListScreenState
    extends State<ChatConversationListScreen> {
  final TextEditingController _textController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(primarySwatch: Colors.purple),
      home: new Material(
        child: new ScopedModelDescendant<ChatConversationListModuleModel>(
          builder: (
            BuildContext context,
            Widget child,
            ChatConversationListModuleModel model,
          ) {
            List<Widget> stackChildren = <Widget>[
              new ChatConversationList(
                conversations: model.conversations == null
                    ? <Conversation>[]
                    : model.conversations,
                onNewConversation: model.showNewConversationForm,
                onSelectConversation: (Conversation c) =>
                    model.setConversationId(c.conversationId),
                selectedId: model.conversationId,
              ),
            ];

            if (model.shouldShowNewConversationForm) {
              stackChildren.addAll(<Widget>[
                new GestureDetector(
                  onTapUp: (_) => model.hideNewConversationForm(),
                  child: new Container(
                    color: Colors.black.withAlpha(180),
                  ),
                ),
                _buildNewConversationForm(model),
              ]);
            }

            return new Stack(
              fit: StackFit.passthrough,
              children: stackChildren,
            );
          },
        ),
      ),
    );
  }

  // TODO(youngseokyoon): make the form prettier.
  // https://fuchsia.atlassian.net/browse/SO-369
  Widget _buildNewConversationForm(ChatConversationListModuleModel model) {
    return new Center(
      child: new Material(
        child: new Container(
          padding: const EdgeInsets.all(8.0),
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new TextField(
                controller: _textController,
                onSubmitted: (String text) =>
                    _handleConversationFormSubmit(model, text),
              ),
              new RaisedButton(
                onPressed: () =>
                    _handleConversationFormSubmit(model, _textController.text),
                child: new Text('CREATE CONVERSATION'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleConversationFormSubmit(
    ChatConversationListModuleModel model,
    String text,
  ) {
    List<String> participants =
        text.split(',').map((String s) => s.trim()).toList();
    model.hideNewConversationForm();
    model.newConversation(participants);
    _textController.clear();
  }
}
