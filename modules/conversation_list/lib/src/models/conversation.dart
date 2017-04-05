// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:models/user.dart';

/// A data model class representing a conversation.
///
/// This class only contains the information necessary to display the chat
/// conversation list. That is, the actual messages are not stored here.
class Conversation {
  /// Conversation id to be used in Ledger.
  final List<int> conversationId;

  /// List of participants in this conversation.
  final List<User> participants;

  /// Snippet of the last message in this conversation.
  final String snippet;

  /// Last updated timestamp of this conversation.
  final DateTime timestamp;

  /// Creates a new instance of [Conversation].
  Conversation({
    this.conversationId,
    this.participants,
    this.snippet,
    this.timestamp,
  });
}
