// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'message.dart';

/// A [Message] model representing a text message.
class TextMessage extends Message {
  /// The [text] message.
  final String text;

  /// Creates a new instance of [TextMessage].
  TextMessage({
    @required DateTime time,
    @required String sender,
    @required this.text,
  })
      : super(
          time: time,
          sender: sender,
        ) {
    assert(text != null);
  }

  @override
  String get type => 'text';

  @override
  Widget buildWidget() => new Text(text);
}
