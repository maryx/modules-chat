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

  /// Constructor
  MessageInput({
    Key key,
    this.onSubmitMessage,
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
      padding: const EdgeInsets.only(
        right: _kPaddingValue,
        bottom: _kPaddingValue,
      ),
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

  Widget buildButtonRow(Color primaryColor) {
    return new Stack(
      children: <Widget>[
        new Row(
          mainAxisAlignment: MainAxisAlignment.start,
          // TODO(dayang): These "attachment buttons" are scaffolded for now
          // We will need to work with design to figure out the exact buttons
          // to have.
          //
          // SO-203
          // https://fuchsia.atlassian.net/browse/SO-203
          children: <Widget>[
            buildAttachmentButton(
              icon: Icons.photo,
              onPressed: () {},
            ),
            buildAttachmentButton(
              icon: Icons.camera_alt,
              onPressed: () {},
            ),
            buildAttachmentButton(
              icon: Icons.videocam,
              onPressed: () {},
            ),
            buildAttachmentButton(
              icon: Icons.gif,
              onPressed: () {},
            ),
            buildAttachmentButton(
              icon: Icons.location_on,
              onPressed: () {},
            ),
          ],
        ),
        new Positioned(
          bottom: 0.0,
          right: 0.0,
          child: buildSendButton(primaryColor),
        ),
      ],
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
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Container(
              padding: const EdgeInsets.only(
                top: _kPaddingValue,
                left: _kPaddingValue,
                right: _kPaddingValue,
              ),
              child: new FuchsiaCompatibleInputField(
                onChanged: _handleInputChange,
                value: _currentInput,
                hintText: 'Send a message',
                onSubmitted: (_) => _handleSubmit(),
              ),
            ),
            buildButtonRow(theme.primaryColor),
          ],
        ),
      ),
    );
  }
}
