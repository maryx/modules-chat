// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:apps.modules.chat.services/chat_content_provider.fidl.dart';
import 'package:meta/meta.dart';

/// Called when a new chat message is received from another user.
typedef Future<Null> MessageReceivedCallback(
  Conversation conversation,
  Message message,
);

/// An [Exception] class used for [ChatException].
abstract class ChatException implements Exception {
  /// The error message associated with this exception.
  final dynamic message;

  /// An optional field to store an inner exception.
  final dynamic innerException;

  /// Creates a new [ChatException] instance.
  ChatException([this.message, this.innerException]);

  @override
  String toString() {
    String result = 'FirebaseException';
    if (message != null) {
      result += ': $message';
    }
    if (innerException != null) {
      result +=
          (message != null ? ', ' : ': ') + 'innerException: $innerException';
    }

    return result;
  }
}

/// An [Exception] thrown when the authentication process has failed.
class ChatAuthenticationException extends ChatException {
  /// Creates a new instance of [ChatAuthenticationException].
  ChatAuthenticationException([dynamic message, dynamic innerException])
      : super(message, innerException);
}

/// An [Exception] thrown when an operation has failed due to permission issues.
class ChatAuthorizationException extends ChatException {
  /// Creates a new instance of [ChatAuthorizationException].
  ChatAuthorizationException([dynamic message, dynamic innerException])
      : super(message, innerException);
}

/// An [Exception] thrown when a network error has occurred while sending a
/// message to another user.
class ChatNetworkException extends ChatException {
  /// Creates a new instance of [ChatNetworkException].
  ChatNetworkException([dynamic message, dynamic innerException])
      : super(message, innerException);
}

/// An abstract class defining a minimal API for sending and receiving chat
/// messages between users.
abstract class ChatMessageTransporter {
  /// Called when a new chat message is received from another user.
  MessageReceivedCallback onReceived;

  /// Creates a new [ChatMessageTransporter] instance.
  ChatMessageTransporter({this.onReceived});

  /// Initializes the [ChatMessageTransporter].
  Future<Null> initialize();

  /// Sends a message to the specified conversation.
  Future<Null> sendMessage({
    @required Conversation conversation,
    @required List<int> messageId,
    @required String type,
    @required String jsonPayload,
  });
}
