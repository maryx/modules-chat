// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'message.dart';

/// A [Message] model representing a Image with a URL.
class ImageUrlMessage extends Message {
  /// The [url] of the image.
  final String url;

  /// Creates a new instance of [ImageUrlMessage].
  ImageUrlMessage({
    @required DateTime time,
    @required String sender,
    @required this.url,
  })
      : super(
          time: time,
          sender: sender,
        ) {
    assert(url != null);
  }

  @override
  String get type => 'image-url';

  @override
  Widget buildWidget() => new Image.network(url);
}
