// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'fuchsia_compatible_input_field.dart';

const double _kPaddingValue = 16.0;

/// UI Widget for message text input
class MessageInput extends StatefulWidget {
  /// Callback for when a new message is submitted
  final ValueChanged<String> onSubmitMessage;

  /// Callback for when the share photo button is tapped
  final VoidCallback onTapSharePhoto;

  /// Constructor
  MessageInput({
    Key key,
    this.onSubmitMessage,
    this.onTapSharePhoto,
  })
      : super(key: key);

  @override
  _MessageInputState createState() => new _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  InputValue _currentInput = InputValue.empty;

  void _handleInputChange(InputValue input) {
    setState(() {
      _currentInput = input;
    });
  }

  void _handleSubmit() {
    config.onSubmitMessage?.call(_currentInput.text);
    setState(() {
      _currentInput = InputValue.empty;
    });
  }

  Widget buildAttachmentButton({
    IconData icon,
    VoidCallback onPressed,
  }) {
    return new InkWell(
      onTap: onPressed,
      child: new Container(
        padding: const EdgeInsets.all(_kPaddingValue),
        child: new Icon(
          icon,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget buildSendButton(Color primaryColor) {
    return new Container(
      padding: const EdgeInsets.all(_kPaddingValue),
      child: new Material(
        color: _currentInput.text.isEmpty ? Colors.grey[300] : primaryColor,
        type: MaterialType.circle,
        elevation: _currentInput.text.isEmpty ? 2 : 4,
        child: new Container(
          width: 40.0,
          height: 40.0,
          child: new InkWell(
            onTap: _currentInput.text.isEmpty ? null : _handleSubmit,
            child: new Center(
              child: new Icon(
                Icons.send,
                color: _currentInput.text.isEmpty
                    ? Colors.grey[500]
                    : Colors.white,
                size: 16.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return new Container(
      decoration: new BoxDecoration(
        border: new Border(
          top: new BorderSide(
            color: Colors.grey[300],
          ),
        ),
      ),
      child: new Material(
        color: Colors.white,
        child: new Row(
          children: <Widget>[
            buildAttachmentButton(
              icon: Icons.photo,
              onPressed: () => config.onTapSharePhoto?.call(),
            ),
            new Expanded(
              flex: 1,
              child: new FuchsiaCompatibleInputField(
                onChanged: _handleInputChange,
                value: _currentInput,
                hintText: 'Type a message',
                onSubmitted: (_) => _handleSubmit(),
              ),
            ),
            buildSendButton(theme.primaryColor),
          ],
        ),
      ),
    );
  }
}
